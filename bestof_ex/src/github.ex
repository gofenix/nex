defmodule BestofEx.GitHub do
  @moduledoc """
  GitHub REST API client for fetching Elixir repository data.
  Works without authentication (60 requests/hour rate limit).
  """

  @base_url "https://api.github.com"
  @per_page 100

  @doc """
  Search GitHub for Elixir repositories with stars > 10000.
  Returns a list of normalized project maps.
  """
  def search_elixir_repos do
    search_elixir_repos(1, [])
  end

  defp search_elixir_repos(page, acc) do
    url = "#{@base_url}/search/repositories"

    params = [
      q: "language:elixir stars:>5000",
      sort: "stars",
      order: "desc",
      per_page: @per_page,
      page: page
    ]

    case Req.get(url, params: params, headers: api_headers()) do
      {:ok, %{status: 200, body: body}} ->
        items = body["items"] || []
        repos = Enum.map(items, &normalize_repo/1)
        all = acc ++ repos

        if length(items) == @per_page do
          # Rate limit: wait 2s between pages
          Process.sleep(2000)
          search_elixir_repos(page + 1, all)
        else
          {:ok, all}
        end

      {:ok, %{status: 403, body: body}} ->
        IO.puts("⚠ GitHub rate limit hit: #{body["message"]}")
        {:error, :rate_limited}

      {:ok, %{status: status, body: body}} ->
        IO.puts("⚠ GitHub API error #{status}: #{inspect(body)}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        IO.puts("⚠ GitHub request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetch latest data for a single repository by full_name (e.g. "phoenixframework/phoenix").
  """
  def get_repo(full_name) do
    url = "#{@base_url}/repos/#{full_name}"

    case Req.get(url, headers: api_headers()) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, normalize_repo(body)}

      {:ok, %{status: 403}} ->
        {:error, :rate_limited}

      {:ok, %{status: status}} ->
        {:error, {:api_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetch topics for a repository.
  """
  def get_repo_topics(full_name) do
    url = "#{@base_url}/repos/#{full_name}/topics"

    case Req.get(url, headers: api_headers()) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body["names"] || []}

      _ ->
        {:ok, []}
    end
  end

  defp normalize_repo(repo) do
    %{
      "name" => repo["name"],
      "full_name" => repo["full_name"],
      "description" => repo["description"] || "",
      "repo_url" => repo["html_url"],
      "homepage_url" => repo["homepage"],
      "stars" => repo["stargazers_count"],
      "avatar_url" => get_in(repo, ["owner", "avatar_url"]),
      "open_issues" => repo["open_issues_count"] || 0,
      "pushed_at" => parse_datetime(repo["pushed_at"]),
      "license" => get_in(repo, ["license", "spdx_id"]),
      "topics" => repo["topics"] || []
    }
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(str) when is_binary(str) do
    case NaiveDateTime.from_iso8601(str) do
      {:ok, ndt} -> ndt
      _ ->
        case DateTime.from_iso8601(str) do
          {:ok, dt, _} -> DateTime.to_naive(dt)
          _ -> nil
        end
    end
  end
  defp parse_datetime(_), do: nil

  defp api_headers do
    [
      {"Accept", "application/vnd.github.v3+json"},
      {"User-Agent", "BestofEx/1.0"}
    ]
  end
end
