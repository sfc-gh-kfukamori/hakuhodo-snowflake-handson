-- ============================================================================
-- 博報堂 Snowflake ハンズオン
-- Section 2: データエンジニアリング（Stream / Task）
-- ============================================================================
-- このセクションでは以下を学びます:
--   1. Stream: テーブルの変更データ（CDC）をキャプチャする仕組み
--   2. Task: SQLをスケジュール実行する仕組み
--   3. Stream + Task の組み合わせによる増分データパイプライン構築
--
-- ★ ポイント:
--   Stream はテーブルへの INSERT/UPDATE/DELETE を追跡し、
--   「前回読み取り以降の差分」だけを取得できます。
--   Task と組み合わせることで「データが来たら自動処理」を実現します。
-- ============================================================================

-- ============================================================================
-- Step 2-0: EXECUTE TASK 権限の付与
-- ============================================================================
-- Task を手動実行（EXECUTE TASK）するには、ロールに対して
-- EXECUTE TASK 権限が必要です。ACCOUNTADMIN で付与します。

USE ROLE ACCOUNTADMIN;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
USE DATABASE HAKUHODO_HANDSON_DB;
USE SCHEMA HAKUHODO_HANDSON_SCHEMA;
USE WAREHOUSE HAKUHODO_HANDSON_WH;

-- ============================================================================
-- Step 2-0b: 既存 Task の停止（再実行時の安全対策）
-- ============================================================================
-- CREATE OR REPLACE でテーブルを再作成すると、既存の Stream が無効になります。
-- Stream を参照する Task が動作中だとエラーになるため、先に停止します。
-- ★ 初回実行時は Task が存在しないためエラーが出ますが無視して進めてください。

ALTER TASK IF EXISTS TASK_LOAD_PURCHASE_WITH_AGENCY SUSPEND;
ALTER TASK IF EXISTS TASK_LOAD_SPECIAL_FEE_SUMMARY SUSPEND;

-- ============================================================================
-- Step 2-1: 加工先テーブルの作成
-- ============================================================================
-- 仕入データに代理店グループ情報を付与し、媒体収益の分析用テーブルを作成します。

CREATE OR REPLACE TABLE HAKUHODO_HANDSON_DB.ANALYTICS.PURCHASE_WITH_AGENCY (
    "RB処理日" NUMBER(8,0),
    "年度_4月起点" NUMBER(4,0),
    "年月" NUMBER(6,0),
    "四半期_4月起点" VARCHAR,
    "会社_営業_名_最新" VARCHAR,
    "営業部門名_最新" VARCHAR,
    "営業部署名_最新" VARCHAR,
    "得意先名" VARCHAR,
    "広告主名" VARCHAR,
    "広告主業種_大名" VARCHAR,
    "広告主業種_中名" VARCHAR,
    "マスメディア区分名" VARCHAR,
    "実施媒体社名" VARCHAR,
    "売上種目名" VARCHAR,
    "媒体種目名" VARCHAR,
    "媒体種類名" VARCHAR,
    "ビークル名" VARCHAR,
    "仕入高予算" NUMBER(38,0),
    "仕入高_建値" NUMBER(38,0),
    "媒体戦略原価B予算" NUMBER(38,0),
    "媒体戦略原価B_正味" NUMBER(38,0),
    "媒体収益予算" NUMBER(38,0),
    "媒体収益実績_正味" NUMBER(38,0),
    "FC営収予算_社内_社外" NUMBER(38,0),
    "FC営収_社内_社外" NUMBER(38,0),
    "スタッフコスト" NUMBER(38,0),
    -- 代理店グループマスタからの付与カラム
    AGENCY_KEY VARCHAR COMMENT '代理店系列 (H:博報堂, D:大広, Y:読広)',
    AGENCY_NAME_LATEST VARCHAR,
    -- メタデータ
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 組織損益データの集計テーブル
CREATE OR REPLACE TABLE HAKUHODO_HANDSON_DB.ANALYTICS.SPECIAL_FEE_SUMMARY (
    "年度" NUMBER(4,0),
    "年月" NUMBER(6,0),
    "四半期" VARCHAR,
    "会社" VARCHAR,
    "部門G" VARCHAR,
    "部門" VARCHAR,
    "管理項目名称" VARCHAR,
    "実績合計" NUMBER(38,0),
    "予算合計" NUMBER(38,0),
    "予実差異" NUMBER(38,0),
    "予実達成率" NUMBER(10,2),
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- Step 2-2: Stream の作成
-- ============================================================================
-- 各RAWテーブルに対して Stream を作成します。
-- Stream はテーブルの変更（INSERT/UPDATE/DELETE）を自動追跡します。

CREATE OR REPLACE STREAM PURCHASE_NEW_TABLE_STREAM
    ON TABLE PURCHASE_NEW_TABLE
    APPEND_ONLY = TRUE    -- INSERTのみ追跡（UPDATE/DELETEは無視）
    COMMENT = '仕入RAWテーブルの変更追跡用Stream';

CREATE OR REPLACE STREAM SPECIAL_FEE_TABLE_STREAM
    ON TABLE SPECIAL_FEE_TABLE
    APPEND_ONLY = TRUE
    COMMENT = '組織損益RAWテーブルの変更追跡用Stream';

-- ★ ここで確認: Stream が作成されたことを確認しましょう
SHOW STREAMS;

-- Stream の中身を確認（まだデータがない状態）
SELECT * FROM PURCHASE_NEW_TABLE_STREAM LIMIT 5;
SELECT * FROM SPECIAL_FEE_TABLE_STREAM LIMIT 5;

-- ============================================================================
-- Step 2-3: Task の作成
-- ============================================================================
-- Task は Stream にデータがある場合にのみ実行される（WHEN句で制御）
-- → 無駄な実行を防ぎ、コストを最適化します

-- Task 1: 仕入データ + 代理店グループマスタ JOIN → PURCHASE_WITH_AGENCY
CREATE OR REPLACE TASK TASK_LOAD_PURCHASE_WITH_AGENCY
    WAREHOUSE = HAKUHODO_HANDSON_WH
    SCHEDULE = '2 MINUTE'    -- 2分ごとにチェック（デモ用。実運用では適切な間隔を設定）
    WHEN SYSTEM$STREAM_HAS_DATA('PURCHASE_NEW_TABLE_STREAM')
    AS
    INSERT INTO HAKUHODO_HANDSON_DB.ANALYTICS.PURCHASE_WITH_AGENCY (
        "RB処理日", "年度_4月起点", "年月", "四半期_4月起点",
        "会社_営業_名_最新", "営業部門名_最新", "営業部署名_最新",
        "得意先名", "広告主名", "広告主業種_大名", "広告主業種_中名",
        "マスメディア区分名", "実施媒体社名", "売上種目名",
        "媒体種目名", "媒体種類名", "ビークル名",
        "仕入高予算", "仕入高_建値",
        "媒体戦略原価B予算", "媒体戦略原価B_正味",
        "媒体収益予算", "媒体収益実績_正味",
        "FC営収予算_社内_社外", "FC営収_社内_社外", "スタッフコスト",
        AGENCY_KEY, AGENCY_NAME_LATEST, LOADED_AT
    )
    SELECT
        p."RB処理日", p."年度_4月起点", p."年月", p."四半期_4月起点",
        p."会社_営業_名_最新", p."営業部門名_最新", p."営業部署名_最新",
        p."得意先名", p."広告主名", p."広告主業種_大名", p."広告主業種_中名",
        p."マスメディア区分名", p."実施媒体社名", p."売上種目名",
        p."媒体種目名", p."媒体種類名", p."ビークル名",
        p."仕入高予算", p."仕入高_建値",
        p."媒体戦略原価B予算", p."媒体戦略原価B_正味",
        p."媒体収益予算", p."媒体収益実績_正味",
        p."FC営収予算_社内_社外", p."FC営収_社内_社外", p."スタッフコスト",
        m.AGENCY_KEY,
        m.AGENCY_NAME_LATEST,
        CURRENT_TIMESTAMP()
    FROM PURCHASE_NEW_TABLE_STREAM p
    LEFT JOIN MST_AGENCY_GROUP m
        ON p."会社_営業_コード_最新" = m.AGENCY_CODE_LATEST;

-- Task 2: 組織損益データの集計 → SPECIAL_FEE_SUMMARY
CREATE OR REPLACE TASK TASK_LOAD_SPECIAL_FEE_SUMMARY
    WAREHOUSE = HAKUHODO_HANDSON_WH
    SCHEDULE = '2 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('SPECIAL_FEE_TABLE_STREAM')
    AS
    INSERT INTO HAKUHODO_HANDSON_DB.ANALYTICS.SPECIAL_FEE_SUMMARY
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
        END AS "予実達成率",
        CURRENT_TIMESTAMP()
    FROM SPECIAL_FEE_TABLE_STREAM
    GROUP BY "年度", "年月", "四半期", "会社", "部門G", "部門", "管理項目名称";

-- ============================================================================
-- Step 2-4: Task の起動
-- ============================================================================
-- Task はデフォルトで SUSPENDED 状態です。明示的に RESUME する必要があります。

ALTER TASK TASK_LOAD_PURCHASE_WITH_AGENCY RESUME;
ALTER TASK TASK_LOAD_SPECIAL_FEE_SUMMARY RESUME;

-- ★ ここで確認: Task の状態を確認しましょう
SHOW TASKS;

-- ============================================================================
-- Step 2-5: Stream + Task の動作確認
-- ============================================================================
-- RAWテーブルにテストデータを INSERT して、Stream → Task の自動処理を確認します。

-- テストデータの INSERT（仕入データにサンプル行を追加）
INSERT INTO PURCHASE_NEW_TABLE (
    "RB処理日", "年度_4月起点", "年月", "四半期_4月起点",
    "会社_営業_コード_最新", "会社_営業_名_最新",
    "営業部門コード_最新", "営業部門名_最新",
    "営業部署コード_最新", "営業部署名_最新",
    "得意先名", "広告主名", "広告主業種_大名",
    "マスメディア区分名", "媒体種類名",
    "仕入高_建値", "媒体収益実績_正味"
) VALUES (
    20250401, 2025, 202504, '1Q',
    'H001', '株式会社博報堂',
    'D001', 'テスト営業部門',
    'S001', 'テスト営業部署',
    'テスト得意先', 'テスト広告主', 'テスト業種',
    'テレビ', 'テスト媒体',
    1000000, 500000
);

-- Stream にデータが入ったことを確認
SELECT * FROM PURCHASE_NEW_TABLE_STREAM;

-- ★ ここで確認: 5分以内に Task が自動実行されることを待ちましょう
-- 待てない場合は手動で Task を実行することもできます:
EXECUTE TASK TASK_LOAD_PURCHASE_WITH_AGENCY;

-- 加工先テーブルにデータが入ったことを確認
SELECT * FROM HAKUHODO_HANDSON_DB.ANALYTICS.PURCHASE_WITH_AGENCY
ORDER BY LOADED_AT DESC
LIMIT 10;

-- ============================================================================
-- Step 2-6: Task の実行履歴確認
-- ============================================================================
-- Task の実行状況はモニタリングできます。

SELECT
    NAME,
    STATE,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    ERROR_CODE,
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME => 'TASK_LOAD_PURCHASE_WITH_AGENCY',
    SCHEDULED_TIME_RANGE_START => DATEADD('HOUR', -1, CURRENT_TIMESTAMP())
))
ORDER BY SCHEDULED_TIME DESC
LIMIT 10;

-- ============================================================================
-- Step 2-7: クリーンアップ（次のセクションに進む前に Task を停止）
-- ============================================================================
-- ★ 重要: Task は RESUME のまま放置するとスケジュール実行され続けます。
--   ハンズオン中は停止しておきましょう。

ALTER TASK TASK_LOAD_PURCHASE_WITH_AGENCY SUSPEND;
ALTER TASK TASK_LOAD_SPECIAL_FEE_SUMMARY SUSPEND;

-- ============================================================================
-- ★ 学びのポイント:
--   - Stream + Task はデータ変更を「検知 → 自動処理」するパターン
--   - 命令的（Imperative）アプローチ: 「何をどう処理するか」を明示的に記述
--   - メリット: 処理の細かい制御が可能、エラーハンドリングを柔軟に実装できる
--   - デメリット: 定義するオブジェクトが多く管理が複雑になりやすい
--
-- → 次のセクションでは、同じ処理を Dynamic Table で実現する
--   「宣言的（Declarative）」アプローチを学びます。
-- ============================================================================
-- 次のステップ: 03_data_engineering_dynamic_table.sql に進んでください
-- ============================================================================
