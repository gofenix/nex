# Script to clean duplicate papers
# Run: cd ai_saga && elixir scripts/clean_duplicates.exs

# Initialize environment
Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

# Use NexBase to query and delete duplicate papers
# Keep the earliest created record for each arxiv_id

# Find all duplicate arxiv_ids (excluding null)
{:ok, duplicates} =
  NexBase.sql(
    """
      SELECT arxiv_id, COUNT(*) as count
      FROM aisaga_papers
      WHERE arxiv_id IS NOT NULL
      GROUP BY arxiv_id
      HAVING COUNT(*) > 1
    """,
    []
  )

IO.puts("Found #{length(duplicates)} duplicate arxiv_ids\n")

Enum.each(duplicates, fn dup ->
  arxiv_id = dup["arxiv_id"]
  count = dup["count"]

  # Skip null values
  if is_nil(arxiv_id) do
    IO.puts("Skipping null arxiv_id")
  else
    IO.puts("Processing: #{arxiv_id} (#{count} records)")

    # Get all records for this arxiv_id
    {:ok, papers} =
      NexBase.sql(
        """
          SELECT id, slug, created_at
          FROM aisaga_papers
          WHERE arxiv_id = $1
          ORDER BY created_at ASC
        """,
        [arxiv_id]
      )

    # Keep the first one, delete the rest
    [keep | to_delete] = papers

    IO.puts("  Keep: id=#{keep["id"]}, slug=#{keep["slug"]}")

    Enum.each(to_delete, fn paper ->
      id = paper["id"]
      IO.puts("  Delete: id=#{id}, slug=#{paper["slug"]}")

      # First delete paper_authors associations
      {:ok, _} = NexBase.sql("DELETE FROM aisaga_paper_authors WHERE paper_id = $1", [id])

      # Then delete the paper
      {:ok, _} = NexBase.sql("DELETE FROM aisaga_papers WHERE id = $1", [id])
    end)

    IO.puts("")
  end
end)

IO.puts("✅ Cleanup complete!")
