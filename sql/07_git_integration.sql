-- ============================================================================
-- 博報堂 Snowflake ハンズオン
-- Section 7: Snowflake Git Integration（GitHub連携）
-- ============================================================================
-- このセクションでは以下を学びます:
--   1. Snowflake から GitHub リポジトリを直接参照する設定
--   2. Git リポジトリ上の SQL/Python/YAML ファイルを Snowflake で利用
--   3. Workspace での Git 連携作業フロー
--
-- ★ Snowflake Git Integration とは:
--   GitHub 等の Git リポジトリを Snowflake のステージとして参照でき、
--   リポジトリ内のファイル（SQL、Python、YAML等）を直接利用できます。
--   コードとデータの一元管理が可能になります。
-- ============================================================================

USE ROLE SYSADMIN;
USE DATABASE HAKUHODO_HANDSON_DB;
USE SCHEMA HAKUHODO_HANDSON_SCHEMA;
USE WAREHOUSE HAKUHODO_HANDSON_WH;

-- ============================================================================
-- Step 7-1: API Integration の作成（Git 用）
-- ============================================================================
-- GitHub への HTTPS アクセスを許可する API Integration を作成します。
-- ※ ACCOUNTADMIN ロールが必要です。

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION GITHUB_API_INTEGRATION
    API_PROVIDER = GIT_HTTPS_API
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-kfukamori/')
    ENABLED = TRUE
    COMMENT = '博報堂ハンズオン GitHub連携用';

-- SYSADMIN に権限を付与
GRANT USAGE ON INTEGRATION GITHUB_API_INTEGRATION TO ROLE SYSADMIN;

USE ROLE SYSADMIN;

-- ============================================================================
-- Step 7-2: Secret の作成（Private リポジトリの場合のみ必要）
-- ============================================================================
-- ★ Public リポジトリの場合はこのステップはスキップ可能です。
-- Private リポジトリにアクセスする場合は Personal Access Token が必要です。
--
-- CREATE OR REPLACE SECRET GITHUB_PAT
--     TYPE = PASSWORD
--     USERNAME = '<YOUR_GITHUB_USERNAME>'
--     PASSWORD = '<YOUR_GITHUB_PAT>'
--     COMMENT = 'GitHub Personal Access Token';

-- ============================================================================
-- Step 7-3: Git リポジトリオブジェクトの作成
-- ============================================================================
-- GitHub リポジトリを Snowflake のオブジェクトとして登録します。

CREATE OR REPLACE GIT REPOSITORY HAKUHODO_HANDSON_DB.HAKUHODO_HANDSON_SCHEMA.HAKUHODO_HANDSON_REPO
    API_INTEGRATION = GITHUB_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-kfukamori/hakuhodo-snowflake-handson.git'
    COMMENT = '博報堂ハンズオン用GitHubリポジトリ';

-- ★ Private リポジトリの場合は GIT_CREDENTIALS を追加:
-- CREATE OR REPLACE GIT REPOSITORY HAKUHODO_HANDSON_REPO
--     API_INTEGRATION = GITHUB_API_INTEGRATION
--     GIT_CREDENTIALS = GITHUB_PAT
--     ORIGIN = 'https://github.com/sfc-gh-kfukamori/hakuhodo-snowflake-handson.git';

-- ============================================================================
-- Step 7-4: リポジトリの内容を確認
-- ============================================================================

-- リポジトリの最新状態を取得（fetch）
ALTER GIT REPOSITORY HAKUHODO_HANDSON_REPO FETCH;

-- ブランチ一覧を確認
SHOW GIT BRANCHES IN HAKUHODO_HANDSON_REPO;

-- main ブランチのファイル一覧を確認
LIST @HAKUHODO_HANDSON_REPO/branches/main/;

-- SQL ファイルの確認
LIST @HAKUHODO_HANDSON_REPO/branches/main/sql/;

-- データファイルの確認
LIST @HAKUHODO_HANDSON_REPO/branches/main/data/purchase_new_table/;
LIST @HAKUHODO_HANDSON_REPO/branches/main/data/special_fee_table/;
LIST @HAKUHODO_HANDSON_REPO/branches/main/data/mst_agency_group/;

-- Streamlit アプリファイルの確認
LIST @HAKUHODO_HANDSON_REPO/branches/main/streamlit/;

-- Semantic Model の確認
LIST @HAKUHODO_HANDSON_REPO/branches/main/semantic_model/;

-- ============================================================================
-- Step 7-5: Git リポジトリ上のデータからテーブルにロード
-- ============================================================================
-- GCS の代わりに GitHub リポジトリからデータをロードする方法です。
-- ★ GCS外部ステージの代替として、Git上のCSVファイルから直接ロード可能です。

-- ファイルフォーマットの作成（01_external_stage_and_load.sql と同じもの）
CREATE OR REPLACE FILE FORMAT CSV_FORMAT_JP
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    ESCAPE_UNENCLOSED_FIELD = NONE
    ENCODING = 'UTF8'
    NULL_IF = ('', 'NULL', 'null');

-- 仕入RAWデータのロード（Git リポジトリから）
COPY INTO PURCHASE_NEW_TABLE
    FROM @HAKUHODO_HANDSON_REPO/branches/main/data/purchase_new_table/
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

-- 組織損益RAWデータのロード
COPY INTO SPECIAL_FEE_TABLE
    FROM @HAKUHODO_HANDSON_REPO/branches/main/data/special_fee_table/
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

-- 代理店グループマスタのロード
COPY INTO MST_AGENCY_GROUP
    FROM @HAKUHODO_HANDSON_REPO/branches/main/data/mst_agency_group/
    FILE_FORMAT = CSV_FORMAT_JP
    ON_ERROR = 'CONTINUE';

-- ロード結果の確認
SELECT 'PURCHASE_NEW_TABLE' AS table_name, COUNT(*) AS row_count FROM PURCHASE_NEW_TABLE
UNION ALL
SELECT 'SPECIAL_FEE_TABLE', COUNT(*) FROM SPECIAL_FEE_TABLE
UNION ALL
SELECT 'MST_AGENCY_GROUP', COUNT(*) FROM MST_AGENCY_GROUP;

-- ============================================================================
-- Step 7-6: Git リポジトリ上の Semantic Model を利用
-- ============================================================================
-- Semantic Model YAML を Git リポジトリから直接参照できます。

-- Snowflake Intelligence の作成（Git上のYAMLを参照）
-- CREATE OR REPLACE CORTEX ANALYST HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_INTELLIGENCE
--     SEMANTIC_MODEL = '@HAKUHODO_HANDSON_REPO/branches/main/semantic_model/hakuhodo_semantic_model.yaml'
--     COMMENT = '博報堂ハンズオン用 Snowflake Intelligence（Git連携）';

-- ============================================================================
-- Step 7-7: Snowflake Workspace での Git 連携
-- ============================================================================
-- ★ Snowsight Workspace での操作手順:
--
--   1. Snowsight にログイン
--   2. 左メニュー「Projects」→「Worksheets」を開く
--   3. 「+」→「SQL Worksheet from Git Repository」を選択
--   4. リポジトリ: HAKUHODO_HANDSON_REPO を選択
--   5. ブランチ: main を選択
--   6. sql/ フォルダ内の各 SQL ファイルを選択して実行可能
--
-- ★ Git 連携のメリット:
--   - コードのバージョン管理が Git で一元化される
--   - チーム間でのコード共有・レビューが容易
--   - CI/CD パイプラインとの連携が可能
--   - Snowsight から直接 Git 上のファイルを実行できる
--
-- ★ Streamlit アプリの Git 連携:
--   1. Snowsight の「Streamlit」→「+ Streamlit App」
--   2. 「Create from Git Repository」を選択
--   3. リポジトリ: HAKUHODO_HANDSON_REPO
--   4. パス: streamlit/hakuhodo_dashboard.py
--   5. これにより Git 上の最新コードが常に反映される

-- ============================================================================
-- ★ 学びのポイント:
--   - Git Integration により、コードとデータの管理を統合できる
--   - Public リポジトリなら認証なしでアクセス可能
--   - Git上のCSVファイルから COPY INTO でデータロードも可能
--   - Workspace で Git 上のSQLファイルを直接開いて実行できる
--   - Semantic Model や Streamlit アプリも Git から参照可能
-- ============================================================================
