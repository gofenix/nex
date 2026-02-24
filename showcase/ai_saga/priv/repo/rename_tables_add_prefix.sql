-- 重命名所有表，添加 aisaga_ 前缀
-- 在 Supabase 的 SQL Editor 中执行

-- 1. 重命名主表
ALTER TABLE IF EXISTS paradigms RENAME TO aisaga_paradigms;
ALTER TABLE IF EXISTS authors RENAME TO aisaga_authors;
ALTER TABLE IF EXISTS papers RENAME TO aisaga_papers;
ALTER TABLE IF EXISTS paper_authors RENAME TO aisaga_paper_authors;
ALTER TABLE IF EXISTS paradigm_relations RENAME TO aisaga_paradigm_relations;

-- 2. 重命名序列（如果使用了 SERIAL/BIGSERIAL）
ALTER SEQUENCE IF EXISTS paradigms_id_seq RENAME TO aisaga_paradigms_id_seq;
ALTER SEQUENCE IF EXISTS authors_id_seq RENAME TO aisaga_authors_id_seq;
ALTER SEQUENCE IF EXISTS papers_id_seq RENAME TO aisaga_papers_id_seq;
ALTER SEQUENCE IF EXISTS paper_authors_id_seq RENAME TO aisaga_paper_authors_id_seq;
ALTER SEQUENCE IF EXISTS paradigm_relations_id_seq RENAME TO aisaga_paradigm_relations_id_seq;

-- 3. 验证重命名结果
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE 'aisaga_%'
ORDER BY table_name;
