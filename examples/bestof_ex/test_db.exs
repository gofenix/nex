# Test database connection
alias BestofEx.Repo

IO.puts("Testing database connection...")

case Repo.start_link() do
  {:ok, pid} ->
    IO.puts("Connected! PID: #{inspect(pid)}")
    Repo.stop(pid)

  {:error, reason} ->
    IO.puts("Failed to connect: #{inspect(reason)}")
end
