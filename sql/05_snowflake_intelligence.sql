-- ============================================================================
-- 博報堂 Snowflake ハンズオン
-- Section 5: Snowflake Intelligence（Cortex Analyst）
-- ============================================================================
-- このセクションでは以下を学びます:
--   1. Semantic Model（意味モデル）の定義
--   2. Snowflake Intelligence の作成とセットアップ
--   3. 自然言語によるデータ問い合わせの実践
--
-- ★ Snowflake Intelligence とは:
--   Semantic Model を基盤に、ビジネスユーザーが自然言語で
--   データに質問できるチャットインターフェースです。
--   SQLを書かずにデータ分析ができるため、非エンジニアでも活用可能です。
--
-- ★ Semantic Model とは:
--   テーブルやカラムに「ビジネス上の意味」を付与する定義ファイル(YAML)です。
--   「仕入高」がどのカラムを指すか、「年度」でどうフィルタするか等を定義します。
-- ============================================================================

USE ROLE SYSADMIN;
USE DATABASE HAKUHODO_HANDSON_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE HAKUHODO_HANDSON_WH;

-- ============================================================================
-- Step 5-1: Semantic Model 用ステージの作成
-- ============================================================================
-- Semantic Model の YAML ファイルを格納するステージを作成します。

CREATE STAGE IF NOT EXISTS HAKUHODO_HANDSON_DB.ANALYTICS.SEMANTIC_MODEL_STAGE
    COMMENT = 'Semantic Model YAML格納用ステージ';

-- ============================================================================
-- Step 5-2: Semantic Model YAML の定義
-- ============================================================================
-- 以下の YAML を hakuhodo_semantic_model.yaml として保存し、
-- ステージにアップロードしてください。
--
-- ★ アップロード方法:
--   PUT file:///path/to/hakuhodo_semantic_model.yaml
--       @HAKUHODO_HANDSON_DB.ANALYTICS.SEMANTIC_MODEL_STAGE
--       AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--
-- ★ または Snowsight の「Data」→ ステージ画面から直接アップロード可能です。
-- ============================================================================

-- ★★★ 以下が hakuhodo_semantic_model.yaml の内容です ★★★
/*
name: hakuhodo_handson_model
description: >
  博報堂ハンズオン用セマンティックモデル。
  仕入データ・組織損益データを自然言語で分析するための定義。

tables:

  - name: purchase_monthly_summary
    description: >
      仕入データの月次集計テーブル。媒体種類別・業種別・代理店系列別の
      仕入高、媒体収益、FC営収などの指標を月単位で集計したデータ。
    base_table:
      database: HAKUHODO_HANDSON_DB
      schema: ANALYTICS
      table: DT_PURCHASE_MONTHLY_SUMMARY

    dimensions:
      - name: fiscal_year
        synonyms:
          - 年度
          - 会計年度
        description: 4月起点の会計年度
        expr: '"年度_4月起点"'
        data_type: NUMBER

      - name: year_month
        synonyms:
          - 年月
          - 月
        description: 年月（YYYYMM形式）
        expr: '"年月"'
        data_type: NUMBER

      - name: quarter
        synonyms:
          - 四半期
          - Q
        description: 4月起点の四半期（1Q〜4Q）
        expr: '"四半期_4月起点"'
        data_type: VARCHAR

      - name: sales_company
        synonyms:
          - 会社
          - 営業会社
        description: 営業担当会社名
        expr: '"会社_営業_名_最新"'
        data_type: VARCHAR

      - name: advertiser_industry_large
        synonyms:
          - 広告主業種
          - 業種大分類
          - 業種
        description: 広告主の業種大分類
        expr: '"広告主業種_大名"'
        data_type: VARCHAR

      - name: mass_media_category
        synonyms:
          - マスメディア区分
          - メディア区分
        description: マスメディアの区分（テレビ、新聞、雑誌、ラジオ等）
        expr: '"マスメディア区分名"'
        data_type: VARCHAR

      - name: media_type
        synonyms:
          - 媒体種類
          - メディア種類
        description: 媒体の種類
        expr: '"媒体種類名"'
        data_type: VARCHAR

      - name: agency_group
        synonyms:
          - 代理店系列
          - 代理店グループ
          - 系列
        description: 代理店系列（H:博報堂, D:大広, Y:読広）
        expr: AGENCY_KEY
        data_type: VARCHAR

    measures:
      - name: total_purchase
        synonyms:
          - 仕入高
          - 仕入高合計
          - 仕入
        description: 仕入高の合計金額
        expr: SUM("仕入高合計")
        data_type: NUMBER

      - name: total_media_revenue
        synonyms:
          - 媒体収益
          - 媒体収益合計
        description: 媒体収益の実績合計
        expr: SUM("媒体収益合計")
        data_type: NUMBER

      - name: total_media_budget
        synonyms:
          - 媒体収益予算
          - 予算
        description: 媒体収益の予算合計
        expr: SUM("媒体収益予算合計")
        data_type: NUMBER

      - name: budget_achievement_rate
        synonyms:
          - 予実達成率
          - 達成率
        description: 媒体収益の予算達成率（%）
        expr: >
          CASE WHEN SUM("媒体収益予算合計") = 0 THEN NULL
          ELSE ROUND(SUM("媒体収益合計") * 100.0 / SUM("媒体収益予算合計"), 1)
          END
        data_type: NUMBER

      - name: total_deals
        synonyms:
          - 取引件数
          - 件数
        description: 取引の件数
        expr: SUM("取引件数")
        data_type: NUMBER

      - name: total_fc_revenue
        synonyms:
          - FC営収
          - FC営業収入
        description: FC営業収入の合計
        expr: SUM("FC営収合計")
        data_type: NUMBER

      - name: total_staff_cost
        synonyms:
          - スタッフコスト
          - 人件費
        description: スタッフコストの合計
        expr: SUM("スタッフコスト合計")
        data_type: NUMBER

  - name: special_fee_summary
    description: >
      組織損益の集計テーブル。会社・部門別の予算と実績を管理項目ごとに
      集計したデータ。予実差異と達成率を含む。
    base_table:
      database: HAKUHODO_HANDSON_DB
      schema: ANALYTICS
      table: DT_SPECIAL_FEE_SUMMARY

    dimensions:
      - name: fiscal_year
        synonyms:
          - 年度
        description: 会計年度
        expr: '"年度"'
        data_type: NUMBER

      - name: year_month
        synonyms:
          - 年月
        description: 年月（YYYYMM形式）
        expr: '"年月"'
        data_type: NUMBER

      - name: quarter
        synonyms:
          - 四半期
        description: 四半期
        expr: '"四半期"'
        data_type: VARCHAR

      - name: company
        synonyms:
          - 会社
        description: 会社名
        expr: '"会社"'
        data_type: VARCHAR

      - name: department_group
        synonyms:
          - 部門グループ
          - 部門G
        description: 部門グループ
        expr: '"部門G"'
        data_type: VARCHAR

      - name: department
        synonyms:
          - 部門
        description: 部門名
        expr: '"部門"'
        data_type: VARCHAR

      - name: management_item
        synonyms:
          - 管理項目
          - 項目
        description: 管理項目名称
        expr: '"管理項目名称"'
        data_type: VARCHAR

    measures:
      - name: total_actual
        synonyms:
          - 実績
          - 実績合計
        description: 実績の合計金額
        expr: SUM("実績合計")
        data_type: NUMBER

      - name: total_budget
        synonyms:
          - 予算
          - 予算合計
        description: 予算の合計金額
        expr: SUM("予算合計")
        data_type: NUMBER

      - name: budget_variance
        synonyms:
          - 予実差異
          - 差異
        description: 実績 - 予算の差異
        expr: SUM("予実差異")
        data_type: NUMBER

      - name: budget_achievement_rate
        synonyms:
          - 予実達成率
          - 達成率
        description: 予算達成率（%）
        expr: >
          CASE WHEN SUM("予算合計") = 0 THEN NULL
          ELSE ROUND(SUM("実績合計") * 100.0 / SUM("予算合計"), 1)
          END
        data_type: NUMBER

verified_queries:

  - name: purchase_by_media_type
    question: 媒体種類別の仕入高を教えてください
    verified_at: 1712000000
    verified_by: handson_admin
    sql: >
      SELECT "媒体種類名", SUM("仕入高合計") AS "仕入高合計"
      FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
      WHERE "媒体種類名" IS NOT NULL
      GROUP BY "媒体種類名"
      ORDER BY "仕入高合計" DESC

  - name: budget_achievement_by_dept
    question: 部門別の予算達成率を教えてください
    verified_at: 1712000000
    verified_by: handson_admin
    sql: >
      SELECT "部門", SUM("実績合計") AS "実績",
             SUM("予算合計") AS "予算",
             CASE WHEN SUM("予算合計") = 0 THEN NULL
             ELSE ROUND(SUM("実績合計") * 100.0 / SUM("予算合計"), 1)
             END AS "達成率"
      FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
      GROUP BY "部門"
      ORDER BY "達成率" DESC

  - name: quarterly_purchase_trend
    question: 四半期ごとの仕入高推移を教えてください
    verified_at: 1712000000
    verified_by: handson_admin
    sql: >
      SELECT "四半期_4月起点", SUM("仕入高合計") AS "仕入高合計",
             SUM("媒体収益合計") AS "媒体収益合計"
      FROM HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
      GROUP BY "四半期_4月起点"
      ORDER BY "四半期_4月起点"
*/

-- ============================================================================
-- Step 5-3: YAML ファイルのアップロード
-- ============================================================================
-- ローカルに保存した YAML をステージにアップロードします。
-- ★ 以下のコマンドはローカル環境で実行してください（SnowSQL等）:
--
-- PUT file:///path/to/hakuhodo_semantic_model.yaml
--     @HAKUHODO_HANDSON_DB.ANALYTICS.SEMANTIC_MODEL_STAGE
--     AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- アップロードされたことを確認
LIST @HAKUHODO_HANDSON_DB.ANALYTICS.SEMANTIC_MODEL_STAGE;

-- ============================================================================
-- Step 5-4: Snowflake Intelligence の作成
-- ============================================================================
-- ★ Snowsight での作成手順:
--
--   1. Snowsight にログイン
--   2. 左メニュー「AI & ML」→「Snowflake Intelligence」を選択
--   3. 「+ Intelligence」をクリック
--   4. 以下を設定:
--      - 名前: HAKUHODO_INTELLIGENCE
--      - Warehouse: HAKUHODO_HANDSON_WH
--      - Semantic Model:
--        ステージ上のYAMLファイルを指定
--        @HAKUHODO_HANDSON_DB.ANALYTICS.SEMANTIC_MODEL_STAGE/hakuhodo_semantic_model.yaml
--   5. 「Create」をクリック
--
-- ★ SQLでの作成（プレビュー機能）:

CREATE OR REPLACE CORTEX ANALYST HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_INTELLIGENCE
    SEMANTIC_MODEL = '@HAKUHODO_HANDSON_DB.ANALYTICS.SEMANTIC_MODEL_STAGE/hakuhodo_semantic_model.yaml'
    COMMENT = '博報堂ハンズオン用 Snowflake Intelligence';

-- ============================================================================
-- Step 5-5: Snowflake Intelligence の動作確認
-- ============================================================================
-- ★ Snowsight で Intelligence を開き、以下の質問を試してみましょう:
--
-- 質問例1: 「媒体種類別の仕入高を教えて」
--   → Verified Query にマッチし、正確な結果が返ります
--
-- 質問例2: 「2025年度の予算達成率が最も低い部門は？」
--   → Semantic Model の定義をもとに SQL が自動生成されます
--
-- 質問例3: 「四半期ごとの仕入高推移をグラフで見せて」
--   → チャート形式で結果が表示されます
--
-- 質問例4: 「博報堂系列の媒体収益はいくら？」
--   → AGENCY_KEY = 'H' でフィルタした結果が返ります
--
-- 質問例5: 「マスメディアの中でテレビの仕入高の割合は？」
--   → マスメディア区分でフィルタ＋集計した結果が返ります

-- ============================================================================
-- ★ 学びのポイント:
--   - Semantic Model はビジネス用語とデータの「辞書」の役割
--   - synonyms（同義語）を定義することで、様々な言い回しに対応可能
--   - Verified Queries で「よくある質問」の正確な回答を保証できる
--   - 非エンジニアでも自然言語でデータ分析を開始できる
--   - SQLの知識がなくても、ビジネスの言葉でデータにアクセス可能
-- ============================================================================
-- 次のステップ: 06_ai_functions.sql に進んでください
-- ============================================================================
