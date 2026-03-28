Nex.Env.init()
NexBase.init(url: System.fetch_env!("DATABASE_URL"), start: true)

NexBase.query!(
  """
  CREATE TABLE IF NOT EXISTS aisaga_paradigms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    start_year INTEGER,
    end_year INTEGER,
    crisis TEXT,
    revolution TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
  """,
  []
)

NexBase.query!(
  """
  CREATE TABLE IF NOT EXISTS aisaga_papers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    abstract TEXT,
    published_year INTEGER NOT NULL,
    citations INTEGER DEFAULT 0,
    paradigm_id INTEGER,
    is_paradigm_shift INTEGER DEFAULT 0,
    shift_trigger TEXT,
    is_daily_pick INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
  """,
  []
)

NexBase.query!("DELETE FROM aisaga_papers", [])
NexBase.query!("DELETE FROM aisaga_paradigms", [])

Enum.each(
  [
    {"Perceptron", "perceptron", 1957},
    {"Symbolic AI", "symbolic-ai", 1970},
    {"Connectionism", "connectionism", 1986},
    {"Deep Learning", "deep-learning", 2012},
    {"Transformers", "transformers", 2017}
  ],
  fn {name, slug, start_year} ->
    NexBase.query!(
      """
      INSERT INTO aisaga_paradigms (name, slug, description, start_year)
      VALUES ($1, $2, $3, $4)
      """,
      [name, slug, "#{name} milestone", start_year]
    )
  end
)

{:ok, paradigms} = NexBase.from("aisaga_paradigms") |> NexBase.run()
transformer_id = Enum.find(paradigms, &(&1["slug"] == "transformers"))["id"]
deep_learning_id = Enum.find(paradigms, &(&1["slug"] == "deep-learning"))["id"]

NexBase.query!(
  """
  INSERT INTO aisaga_papers (
    title, slug, abstract, published_year, citations, paradigm_id, is_paradigm_shift, shift_trigger, is_daily_pick, created_at
  ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP)
  """,
  [
    "Attention Is All You Need",
    "attention-is-all-you-need",
    "The paper that introduced the Transformer architecture.",
    2017,
    100_000,
    transformer_id,
    1,
    "Attention replaced recurrence for sequence modeling.",
    1
  ]
)

NexBase.query!(
  """
  INSERT INTO aisaga_papers (
    title, slug, abstract, published_year, citations, paradigm_id, is_paradigm_shift, shift_trigger, is_daily_pick, created_at
  ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, DATETIME('now', '-1 day'))
  """,
  [
    "ImageNet Classification with Deep CNNs",
    "alexnet",
    "A breakthrough that established modern deep learning in vision.",
    2012,
    90_000,
    deep_learning_id,
    1,
    "GPU training made deep CNNs practical.",
    0
  ]
)
