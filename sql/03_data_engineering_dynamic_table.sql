-- ============================================================================
-- 博報堂 Snowflake ハンズオン
-- Section 3: データエンジニアリング（Dynamic Table）
-- ============================================================================
-- このセクションでは以下を学びます:
--   1. Dynamic Table: 宣言的にデータパイプラインを定義する仕組み
--   2. TARGET_LAG によるリフレッシュ制御
--   3. Stream/Task（命令的）との比較
--
-- ★ Dynamic Table とは:
--   「結果をこう定義する」と宣言するだけで、Snowflake が自動的に
--   ソーステーブルの変更を検知して増分リフレッシュしてくれます。
--   Stream/Task のように「どう処理するか」を書く必要がありません。
-- ============================================================================

USE ROLE SYSADMIN;
USE DATABASE HAKUHODO_HANDSON_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE HAKUHODO_HANDSON_WH;

-- ============================================================================
-- Step 3-1: Dynamic Table の作成（仕入データ + 代理店マスタ JOIN）
-- ============================================================================
-- Section 2 の PURCHASE_WITH_AGENCY と同等のロジックを Dynamic Table で実現します。
-- TARGET_LAG = '2 MINUTES' で、ソースデータ変更後2分以内にリフレッシュされます。

CREATE OR REPLACE DYNAMIC TABLE DT_PURCHASE_WITH_AGENCY
    TARGET_LAG = '2 MINUTES'
    WAREHOUSE = HAKUHODO_HANDSON_WH
    AS
    SELECT
        p."RB処理日",
        p."年度_4月起点",
        p."年月",
        p."四半期_4月起点",
        p."会社_営業_コード_最新",
        p."会社_営業_名_最新",
        p."営業部門名_最新",
        p."営業部署名_最新",
        p."得意先コード",
        p."得意先名",
        p."広告主コード",
        p."広告主名",
        p."広告主業種_大名",
        p."広告主業種_中名",
        p."広告主業種_小名",
        p."マスメディア区分名",
        p."実施媒体社名",
        p."売上種目名",
        p."媒体種目名",
        p."媒体種類名",
        p."ビークル名",
        p."仕入高予算",
        p."仕入高_建値",
        p."媒体戦略原価B予算",
        p."媒体戦略原価B_正味",
        p."媒体収益予算",
        p."媒体収益実績_正味",
        p."FC営収予算_社内_社外",
        p."FC営収_社内_社外",
        p."スタッフコスト",
        m.AGENCY_KEY,
        m.AGENCY_NAME_LATEST
    FROM HAKUHODO_HANDSON_DB.HAKUHODO_HANDSON_SCHEMA.PURCHASE_NEW_TABLE p
    LEFT JOIN HAKUHODO_HANDSON_DB.HAKUHODO_HANDSON_SCHEMA.MST_AGENCY_GROUP m
        ON p."会社_営業_コード_最新" = m.AGENCY_CODE_LATEST;

-- ============================================================================
-- Step 3-2: Dynamic Table の作成（組織損益の集計）
-- ============================================================================
-- SPECIAL_FEE_TABLE の集計 + 予実分析も Dynamic Table で定義します。

CREATE OR REPLACE DYNAMIC TABLE DT_SPECIAL_FEE_SUMMARY
    TARGET_LAG = '2 MINUTES'
    WAREHOUSE = HAKUHODO_HANDSON_WH
    AS
    SELECT
        "年度",
        "年月",
        "四半期",
        "会社",
        "部門G",
        "部門",
        "管理項目名称",
        SUM("実績") AS "実績合計",
        SUM("予算") AS "予算合計",
        SUM("実績") - SUM("予算") AS "予実差異",
        CASE
            WHEN SUM("予算") = 0 THEN NULL
            ELSE ROUND(SUM("実績") * 100.0 / SUM("予算"), 2)
        END AS "予実達成率"
    FROM HAKUHODO_HANDSON_DB.HAKUHODO_HANDSON_SCHEMA.SPECIAL_FEE_TABLE
    GROUP BY "年度", "年月", "四半期", "会社", "部門G", "部門", "管理項目名称";

-- ============================================================================
-- Step 3-3: Dynamic Table の連鎖（パイプラインの多段構成）
-- ============================================================================
-- Dynamic Table は他の Dynamic Table をソースにできます。
-- これにより多段の変換パイプラインを宣言的に構築できます。
--
-- ★ ポイント: 各段の TARGET_LAG を設定することで、
--   エンド to エンドの鮮度を制御できます。

-- 仕入データの月次集計（DT_PURCHASE_WITH_AGENCY をソースに）
CREATE OR REPLACE DYNAMIC TABLE DT_PURCHASE_MONTHLY_SUMMARY
    TARGET_LAG = '2 MINUTES'
    WAREHOUSE = HAKUHODO_HANDSON_WH
    AS
    SELECT
        "年度_4月起点",
        "年月",
        "四半期_4月起点",
        "会社_営業_名_最新",
        "広告主業種_大名",
        "マスメディア区分名",
        "媒体種類名",
        AGENCY_KEY,
        COUNT(*) AS "取引件数",
        SUM("仕入高_建値") AS "仕入高合計",
        SUM("媒体収益実績_正味") AS "媒体収益合計",
        SUM("媒体収益予算") AS "媒体収益予算合計",
        SUM("媒体収益実績_正味") - SUM("媒体収益予算") AS "媒体収益予実差異",
        SUM("FC営収_社内_社外") AS "FC営収合計",
        SUM("スタッフコスト") AS "スタッフコスト合計"
    FROM DT_PURCHASE_WITH_AGENCY
    GROUP BY
        "年度_4月起点", "年月", "四半期_4月起点",
        "会社_営業_名_最新", "広告主業種_大名",
        "マスメディア区分名", "媒体種類名", AGENCY_KEY;

-- ============================================================================
-- Step 3-4: Dynamic Table の状態確認
-- ============================================================================

-- Dynamic Table の一覧と設定を確認
SHOW DYNAMIC TABLES IN SCHEMA ANALYTICS;

-- リフレッシュ状態を確認
SELECT
    NAME,
    STATE,
    STATE_MESSAGE,
    REFRESH_ACTION,
    REFRESH_TRIGGER,
    DATA_TIMESTAMP
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
    NAME_PREFIX => 'HAKUHODO_HANDSON_DB.ANALYTICS.DT_'
))
ORDER BY DATA_TIMESTAMP DESC
LIMIT 10;

-- データが入っていることを確認
SELECT COUNT(*) AS ROW_COUNT FROM DT_PURCHASE_WITH_AGENCY;
SELECT COUNT(*) AS ROW_COUNT FROM DT_SPECIAL_FEE_SUMMARY;
SELECT COUNT(*) AS ROW_COUNT FROM DT_PURCHASE_MONTHLY_SUMMARY;

-- サンプルデータを確認
SELECT * FROM DT_PURCHASE_MONTHLY_SUMMARY
ORDER BY "年月" DESC, "仕入高合計" DESC
LIMIT 20;

-- ============================================================================
-- Step 3-5: Dynamic Table の動作確認（増分リフレッシュ）
-- ============================================================================
-- ソーステーブルにデータを追加して、Dynamic Table が自動更新されることを確認

-- 追加前の件数を記録
SELECT COUNT(*) AS "追加前件数" FROM DT_PURCHASE_WITH_AGENCY;

-- ソーステーブルにテストデータを追加
INSERT INTO HAKUHODO_HANDSON_DB.HAKUHODO_HANDSON_SCHEMA.PURCHASE_NEW_TABLE (
    "RB処理日", "年度_4月起点", "年月", "四半期_4月起点",
    "会社_営業_コード_最新", "会社_営業_名_最新",
    "営業部門コード_最新", "営業部門名_最新",
    "営業部署コード_最新", "営業部署名_最新",
    "得意先名", "広告主名", "広告主業種_大名",
    "マスメディア区分名", "媒体種類名",
    "仕入高_建値", "媒体収益実績_正味"
) VALUES (
    20250402, 2025, 202504, '1Q',
    'D001', '株式会社大広',
    'D002', 'DT確認用部門',
    'S002', 'DT確認用部署',
    'DT確認得意先', 'DT確認広告主', 'DT確認業種',
    'デジタル', 'DT確認媒体',
    2000000, 800000
);

-- ★ ここで確認: 5分後に Dynamic Table が自動リフレッシュされます
-- 手動でリフレッシュしたい場合:
ALTER DYNAMIC TABLE DT_PURCHASE_WITH_AGENCY REFRESH;

-- 追加後の件数を確認（増えていること）
SELECT COUNT(*) AS "追加後件数" FROM DT_PURCHASE_WITH_AGENCY;

-- ============================================================================
-- Step 3-6: Stream/Task vs Dynamic Table 比較まとめ
-- ============================================================================
-- ┌──────────────────────┬───────────────────────┬─────────────────────────┐
-- │ 観点                 │ Stream + Task          │ Dynamic Table           │
-- ├──────────────────────┼───────────────────────┼─────────────────────────┤
-- │ アプローチ           │ 命令的 (Imperative)    │ 宣言的 (Declarative)    │
-- │ 定義方法             │ Stream/Task/           │ SELECT文1つで定義       │
-- │                      │ 加工先テーブルを       │                         │
-- │                      │ それぞれ作成           │                         │
-- │ 増分処理             │ Stream で差分取得し    │ Snowflake が自動判断    │
-- │                      │ INSERT文を記述         │                         │
-- │ スケジュール         │ SCHEDULE句で明示指定   │ TARGET_LAG で鮮度指定   │
-- │ エラーハンドリング   │ 柔軟にカスタマイズ可   │ Snowflake が自動管理    │
-- │ 多段パイプライン     │ Task の依存関係で構築  │ DT同士を参照するだけ    │
-- │ 管理の手間           │ 多い（複数オブジェクト）│ 少ない（DT1つで完結）   │
-- │ 適したケース         │ 複雑なエラー処理や     │ シンプルな変換・集計     │
-- │                      │ 条件分岐が必要な場合   │ パイプライン             │
-- └──────────────────────┴───────────────────────┴─────────────────────────┘
--
-- ★ 推奨:
--   まず Dynamic Table で実現できないか検討し、
--   複雑な制御が必要な場合のみ Stream + Task を使う。
-- ============================================================================
-- 次のステップ: 04_streamlit_dashboard.sql に進んでください
-- ============================================================================
