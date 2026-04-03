-- ============================================================================
-- 博報堂 Snowflake ハンズオン
-- Section 1: GCS外部ステージ定義 & データロード
-- ============================================================================
-- このセクションでは以下を学びます:
--   1. GCS (Google Cloud Storage) をSnowflakeの外部ステージとして定義
--   2. CSVファイルからSnowflakeテーブルへデータをロード
--   3. ウェアハウスサイズによるロード性能の違いを体験
-- ============================================================================

USE ROLE SYSADMIN;
USE DATABASE HAKUHODO_HANDSON_DB;
USE SCHEMA HAKUHODO_HANDSON_SCHEMA;
USE WAREHOUSE HAKUHODO_HANDSON_WH;

-- ============================================================================
-- Step 1-1: Storage Integration の作成
-- ============================================================================
-- Storage Integration は、Snowflake が GCS バケットに安全にアクセスするための
-- 認証情報を管理するオブジェクトです。
-- ※ ACCOUNTADMIN ロールが必要です。

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE STORAGE INTEGRATION GCS_HAKUHODO_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'GCS'
    ENABLED = TRUE
    STORAGE_ALLOWED_LOCATIONS = (
        'gcs://hakuhodo_handson/'
    );

-- Integration の情報を確認（サービスアカウントのメールアドレスを取得）
-- ※ このメールアドレスに GCS バケットの読み取り権限を付与する必要があります
DESC STORAGE INTEGRATION GCS_HAKUHODO_INTEGRATION;

-- SYSADMIN に Integration の使用権限を付与
GRANT USAGE ON INTEGRATION GCS_HAKUHODO_INTEGRATION TO ROLE SYSADMIN;

USE ROLE SYSADMIN;

-- ============================================================================
-- Step 1-2: ファイルフォーマットの作成
-- ============================================================================
-- GCS上のCSVファイルの形式を定義します。
-- データの区切り文字、ヘッダーの有無、エンコーディングなどを指定します。

CREATE OR REPLACE FILE FORMAT HAKUHODO_HANDSON_DB.HAKUHODO_HANDSON_SCHEMA.CSV_FORMAT_JP
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    ESCAPE_UNENCLOSED_FIELD = NONE
    ENCODING = 'UTF8'
    NULL_IF = ('', 'NULL', 'null')
    COMMENT = '日本語CSVファイル用フォーマット';

-- ============================================================================
-- Step 1-3: 外部ステージの作成
-- ============================================================================
-- 外部ステージは GCS バケットへのパスを定義するオブジェクトです。
-- COPY INTO コマンドでこのステージを参照してデータをロードします。

CREATE OR REPLACE STAGE HAKUHODO_HANDSON_DB.HAKUHODO_HANDSON_SCHEMA.GCS_HAKUHODO_STAGE
    STORAGE_INTEGRATION = GCS_HAKUHODO_INTEGRATION
    URL = 'gcs://hakuhodo_handson/'
    FILE_FORMAT = CSV_FORMAT_JP
    COMMENT = '博報堂データ格納用GCS外部ステージ';

-- ステージ内のファイルを確認
-- ★ 以下のコマンドでGCS上のファイル一覧が見えることを確認しましょう
LIST @GCS_HAKUHODO_STAGE;

-- ============================================================================
-- Step 1-4: テーブルの作成
-- ============================================================================

-- (1) 仕入RAWデータテーブル
CREATE OR REPLACE TABLE PURCHASE_NEW_TABLE (
    "RB処理日" NUMBER(8,0),
    "年度_4月起点" NUMBER(4,0),
    "年月" NUMBER(6,0),
    "四半期_4月起点" VARCHAR(16777216),
    "会社_営業_コード_最新" VARCHAR(16777216),
    "会社_営業_名_最新" VARCHAR(16777216),
    "営業部門コード_最新" VARCHAR(16777216),
    "営業部門名_最新" VARCHAR(16777216),
    "営業部署コード_最新" VARCHAR(16777216),
    "営業部署名_最新" VARCHAR(16777216),
    "会社_G発注元コード_最新" VARCHAR(16777216),
    "会社_G発注元名_最新" VARCHAR(16777216),
    "G発注元部門コード_最新" VARCHAR(16777216),
    "G発注元部門名_最新" VARCHAR(16777216),
    "G発注元部署コード_最新" VARCHAR(16777216),
    "G発注元部署名_最新" VARCHAR(16777216),
    "会社_制作媒体コード_最新" VARCHAR(16777216),
    "会社_制作媒体名_最新" VARCHAR(16777216),
    "制作媒体部門コード_最新" VARCHAR(16777216),
    "制作媒体部門名_最新" VARCHAR(16777216),
    "制作媒体部署コード_最新" VARCHAR(16777216),
    "制作媒体部署名_最新" VARCHAR(16777216),
    "得意先コード" VARCHAR(16777216),
    "得意先名" VARCHAR(16777216),
    "広告主コード" VARCHAR(16777216),
    "広告主名" VARCHAR(16777216),
    "広告主業種_大コード" VARCHAR(16777216),
    "広告主業種_大名" VARCHAR(16777216),
    "広告主業種_中コード" VARCHAR(16777216),
    "広告主業種_中名" VARCHAR(16777216),
    "広告主業種_小コード" VARCHAR(16777216),
    "広告主業種_小名" VARCHAR(16777216),
    "広告主企業グループコード" VARCHAR(16777216),
    "広告主企業グループ名" VARCHAR(16777216),
    "広告主企業グループ業種_大コード" VARCHAR(16777216),
    "広告主企業グループ業種_大名" VARCHAR(16777216),
    "広告主企業グループ業種_中コード" VARCHAR(16777216),
    "広告主企業グループ業種_中名" VARCHAR(16777216),
    "広告主企業グループ業種_小コード" VARCHAR(16777216),
    "広告主企業グループ業種_小名" VARCHAR(16777216),
    "支払先コード" VARCHAR(16777216),
    "支払先名" VARCHAR(16777216),
    "マスメディア区分" VARCHAR(16777216),
    "マスメディア区分名" VARCHAR(16777216),
    "実施媒体社コード" VARCHAR(16777216),
    "実施媒体社名" VARCHAR(16777216),
    "売上種目コード" VARCHAR(16777216),
    "売上種目名" VARCHAR(16777216),
    "媒体種目コード" VARCHAR(16777216),
    "媒体種目名" VARCHAR(16777216),
    "媒体種類コード" VARCHAR(16777216),
    "媒体種類名" VARCHAR(16777216),
    "ビークルコード" VARCHAR(16777216),
    "ビークル名" VARCHAR(16777216),
    "仕入高予算" NUMBER(38,0),
    "仕入高_建値" NUMBER(38,0),
    "媒体戦略原価B予算" NUMBER(38,0),
    "媒体戦略原価B_正味" NUMBER(38,0),
    "媒体収益予算" NUMBER(38,0),
    "媒体収益実績_正味" NUMBER(38,0),
    "FC営収予算_社内_社外" NUMBER(38,0),
    "FC営収_社内_社外" NUMBER(38,0),
    "スタッフコスト" NUMBER(38,0)
);

-- (2) 組織損益RAWデータテーブル
CREATE OR REPLACE TABLE SPECIAL_FEE_TABLE (
    "RB処理日" NUMBER(8,0),
    "会社" VARCHAR(16777216),
    "部門G" VARCHAR(16777216),
    "部門" VARCHAR(16777216),
    "部署" VARCHAR(16777216),
    "年度" NUMBER(4,0),
    "年月" NUMBER(6,0),
    "四半期" VARCHAR(16777216),
    "管理項目コード" NUMBER(6,0),
    "管理項目名称" VARCHAR(16777216),
    "補助項目コード" VARCHAR(16777216),
    "補助項目名称" VARCHAR(16777216),
    "実績" NUMBER(11,0),
    "予算" NUMBER(11,0)
);

-- (3) 代理店グループマスタテーブル
CREATE OR REPLACE TABLE MST_AGENCY_GROUP (
    AGENCY_CODE_LATEST VARCHAR(16777216),
    AGENCY_NAME_LATEST VARCHAR(16777216),
    AGENCY_KEY VARCHAR(16777216)
);

-- ============================================================================
-- Step 1-5: データロード（ウェアハウスサイズ X-SMALL）
-- ============================================================================
-- まず X-SMALL サイズでデータをロードし、所要時間を確認します。

ALTER WAREHOUSE HAKUHODO_HANDSON_WH SET WAREHOUSE_SIZE = 'X-SMALL';
ALTER WAREHOUSE HAKUHODO_HANDSON_WH SUSPEND;
ALTER WAREHOUSE HAKUHODO_HANDSON_WH RESUME;

-- ★ ロード開始（X-SMALL）
-- ファイル名は実際のGCS上のファイル名に合わせて調整してください

COPY INTO PURCHASE_NEW_TABLE
    FROM @GCS_HAKUHODO_STAGE/purchase_new_table/    -- ★ 実際のパスに合わせてください
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

COPY INTO SPECIAL_FEE_TABLE
    FROM @GCS_HAKUHODO_STAGE/special_fee_table/     -- ★ 実際のパスに合わせてください
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

COPY INTO MST_AGENCY_GROUP
    FROM @GCS_HAKUHODO_STAGE/mst_agency_group/      -- ★ 実際のパスに合わせてください
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

-- ★ ここで確認: Query History でロード時間を確認しましょう
-- Snowsight の Activity > Query History から直前の COPY INTO の実行時間を確認できます。
-- または以下のクエリで確認:
SELECT QUERY_ID, QUERY_TEXT, TOTAL_ELAPSED_TIME/1000 AS ELAPSED_SEC,
       WAREHOUSE_SIZE, ROWS_PRODUCED
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY_BY_SESSION())
WHERE QUERY_TEXT ILIKE '%COPY INTO%'
ORDER BY START_TIME DESC
LIMIT 10;

-- ロードされたデータを確認
SELECT COUNT(*) AS ROW_COUNT FROM PURCHASE_NEW_TABLE;
SELECT COUNT(*) AS ROW_COUNT FROM SPECIAL_FEE_TABLE;
SELECT COUNT(*) AS ROW_COUNT FROM MST_AGENCY_GROUP;

-- ============================================================================
-- Step 1-6: ウェアハウスサイズ変更によるロード性能比較
-- ============================================================================
-- Snowflake ではウェアハウスサイズを変更するだけで処理能力をスケールできます。
-- テーブルをTRUNCATEして再ロードし、サイズごとの時間を比較します。
--
-- ★ ポイント: ウェアハウスサイズが1段階上がるとコンピュートリソースは2倍になります
--   X-SMALL (1 credit/h) → SMALL (2) → MEDIUM (4) → LARGE (8)

-- --------------------------------------------------------------------------
-- 比較テスト: SMALL サイズ
-- --------------------------------------------------------------------------
TRUNCATE TABLE PURCHASE_NEW_TABLE;
TRUNCATE TABLE SPECIAL_FEE_TABLE;
TRUNCATE TABLE MST_AGENCY_GROUP;

ALTER WAREHOUSE HAKUHODO_HANDSON_WH SET WAREHOUSE_SIZE = 'SMALL';
ALTER WAREHOUSE HAKUHODO_HANDSON_WH SUSPEND;
ALTER WAREHOUSE HAKUHODO_HANDSON_WH RESUME;

COPY INTO PURCHASE_NEW_TABLE
    FROM @GCS_HAKUHODO_STAGE/purchase_new_table/
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

COPY INTO SPECIAL_FEE_TABLE
    FROM @GCS_HAKUHODO_STAGE/special_fee_table/
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

COPY INTO MST_AGENCY_GROUP
    FROM @GCS_HAKUHODO_STAGE/mst_agency_group/
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

-- --------------------------------------------------------------------------
-- 比較テスト: MEDIUM サイズ
-- --------------------------------------------------------------------------
TRUNCATE TABLE PURCHASE_NEW_TABLE;
TRUNCATE TABLE SPECIAL_FEE_TABLE;
TRUNCATE TABLE MST_AGENCY_GROUP;

ALTER WAREHOUSE HAKUHODO_HANDSON_WH SET WAREHOUSE_SIZE = 'MEDIUM';
ALTER WAREHOUSE HAKUHODO_HANDSON_WH SUSPEND;
ALTER WAREHOUSE HAKUHODO_HANDSON_WH RESUME;

COPY INTO PURCHASE_NEW_TABLE
    FROM @GCS_HAKUHODO_STAGE/purchase_new_table/
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

COPY INTO SPECIAL_FEE_TABLE
    FROM @GCS_HAKUHODO_STAGE/special_fee_table/
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

COPY INTO MST_AGENCY_GROUP
    FROM @GCS_HAKUHODO_STAGE/mst_agency_group/
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

-- --------------------------------------------------------------------------
-- 結果比較: 各サイズのロード時間を一覧で確認
-- --------------------------------------------------------------------------
-- ★ ここで確認: 以下のクエリでサイズごとのロード時間を比較してみましょう
SELECT
    WAREHOUSE_SIZE,
    QUERY_TEXT,
    TOTAL_ELAPSED_TIME / 1000 AS ELAPSED_SECONDS,
    ROWS_PRODUCED,
    START_TIME
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY_BY_SESSION())
WHERE QUERY_TEXT ILIKE '%COPY INTO%'
ORDER BY START_TIME DESC
LIMIT 20;

-- ★ 気づきポイント:
--   - ウェアハウスサイズを上げるとロード時間が短縮される
--   - データ量が多いほどスケールアップの効果が顕著になる
--   - コスト(credit/h)は倍になるが、処理時間が半減すれば総コストは同等
--   → 大量データ処理時はサイズアップ→処理→サイズダウンの運用が有効

-- ハンズオン後はコスト節約のためサイズを戻しておく
ALTER WAREHOUSE HAKUHODO_HANDSON_WH SET WAREHOUSE_SIZE = 'X-SMALL';

-- ============================================================================
-- Step 1-7: リザルトキャッシュの体験
-- ============================================================================
-- Snowflake は同一クエリの結果を自動キャッシュします（Result Cache）。
-- 同じクエリを2回実行すると、2回目はウェアハウスを使わず即座に結果を返します。
--
-- ★ ポイント:
--   - キャッシュはユーザー単位ではなくウェアハウス単位で共有される
--   - ソーステーブルのデータが変更されるとキャッシュは無効化される
--   - キャッシュヒット時はウェアハウスが起動しないためクレジット消費ゼロ
--   - 24時間以内の同一クエリに有効
-- ============================================================================

-- ★ 1回目: 仕入データ × 代理店マスタの JOIN + 集計クエリ
-- Query Profile で「WAREHOUSE」ノードが実行されることを確認してください
SELECT
    m.AGENCY_KEY                     AS "代理店系列",
    m.AGENCY_NAME_LATEST             AS "代理店名",
    p."広告主業種_大名"               AS "業種",
    COUNT(*)                         AS "取引件数",
    SUM(p."仕入高_建値")             AS "仕入高合計",
    SUM(p."媒体収益実績_正味")       AS "媒体収益合計",
    ROUND(SUM(p."媒体収益実績_正味") * 100.0
        / NULLIF(SUM(p."仕入高_建値"), 0), 2) AS "収益率%"
FROM PURCHASE_NEW_TABLE p
JOIN MST_AGENCY_GROUP m
    ON p."会社_営業_コード_最新" = m.AGENCY_CODE_LATEST
GROUP BY m.AGENCY_KEY, m.AGENCY_NAME_LATEST, p."広告主業種_大名"
ORDER BY "仕入高合計" DESC
LIMIT 20;

-- ★ 2回目: まったく同じクエリを実行
-- Query Profile を開き「QUERY RESULT REUSE」と表示されることを確認してください
-- → ウェアハウスが使われず、実行時間がほぼ 0ms になります
SELECT
    m.AGENCY_KEY                     AS "代理店系列",
    m.AGENCY_NAME_LATEST             AS "代理店名",
    p."広告主業種_大名"               AS "業種",
    COUNT(*)                         AS "取引件数",
    SUM(p."仕入高_建値")             AS "仕入高合計",
    SUM(p."媒体収益実績_正味")       AS "媒体収益合計",
    ROUND(SUM(p."媒体収益実績_正味") * 100.0
        / NULLIF(SUM(p."仕入高_建値"), 0), 2) AS "収益率%"
FROM PURCHASE_NEW_TABLE p
JOIN MST_AGENCY_GROUP m
    ON p."会社_営業_コード_最新" = m.AGENCY_CODE_LATEST
GROUP BY m.AGENCY_KEY, m.AGENCY_NAME_LATEST, p."広告主業種_大名"
ORDER BY "仕入高合計" DESC
LIMIT 20;

-- ★ 確認方法:
--   Snowsight の Query History で2つのクエリを比較してください。
--   1回目: 実行時間 = 数百ms〜数秒、Bytes scanned > 0
--   2回目: 実行時間 = ほぼ 0ms、Bytes scanned = 0 (QUERY RESULT REUSE)

-- ============================================================================
-- データロード完了
-- 次のステップ: 02_data_engineering_stream_task.sql に進んでください
-- ============================================================================
