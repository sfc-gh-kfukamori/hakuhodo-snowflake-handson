-- ============================================================================
-- 博報堂 Snowflake ハンズオン
-- Section 5: Snowflake Intelligence（セマンティックビュー + Cortex Analyst）
-- ============================================================================
-- このセクションでは以下を学びます:
--   1. セマンティックビュー（Semantic View）の作成
--   2. Snowflake Intelligence の作成とセットアップ
--   3. 自然言語によるデータ問い合わせの実践
--
-- ★ セマンティックビューとは:
--   テーブルやカラムに「ビジネス上の意味」を SQL で定義するオブジェクトです。
--   「仕入高」がどのカラムを指すか、「年度」でどうフィルタするか等を定義し、
--   Cortex Analyst が自然言語からSQLを正確に生成できるようにします。
--
-- ★ YAML ファイルとの違い:
--   従来は YAML ファイルをステージにアップロードする方式でしたが、
--   セマンティックビューは SQL で直接定義でき、バージョン管理やCI/CDとの
--   統合が容易です。Snowflake が推奨する新しい方式です。
-- ============================================================================

USE ROLE SYSADMIN;
USE DATABASE HAKUHODO_HANDSON_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE HAKUHODO_HANDSON_WH;

-- ============================================================================
-- Step 5-1: セマンティックビューの作成
-- ============================================================================
-- ★ CREATE SEMANTIC VIEW で以下を定義します:
--   - TABLES: 分析対象テーブルの論理名・同義語・コメント
--   - FACTS: 数値カラム（集計の元データ）
--   - DIMENSIONS: 分類カラム（フィルタ・グルーピングに使用）
--   - METRICS: 集計式（SUM, AVG, COUNT, 計算式等）
--   - AI_SQL_GENERATION: SQL生成時のLLMへの追加指示
--
-- ★ ポイント:
--   - WITH SYNONYMS で同義語を定義 → 「仕入高」「仕入」どちらでも認識
--   - COMMENT でカラムの意味を説明 → LLM がカラムの用途を正確に理解
--   - METRICS で計算式を定義 → 予実達成率や収益率を自動計算
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_SEMANTIC_VIEW

  -- -------------------------------------------------------
  -- テーブル定義（論理名・同義語・説明）
  -- -------------------------------------------------------
  TABLES (
    purchase AS HAKUHODO_HANDSON_DB.ANALYTICS.DT_PURCHASE_MONTHLY_SUMMARY
      WITH SYNONYMS = ('仕入データ', '仕入月次集計', '購買データ')
      COMMENT = '月次仕入集計データ。媒体種類別・業種別・代理店系列別の仕入高・媒体収益等を月単位で集計',

    special_fee AS HAKUHODO_HANDSON_DB.ANALYTICS.DT_SPECIAL_FEE_SUMMARY
      WITH SYNONYMS = ('組織損益', '特別費', '予実データ')
      COMMENT = '組織損益の集計データ。会社・部門別の予算と実績を管理項目ごとに集計'
  )

  -- -------------------------------------------------------
  -- ファクト（数値カラム = 集計の元データ）
  -- -------------------------------------------------------
  FACTS (
    -- 仕入テーブルのファクト
    purchase.f_deals AS "取引件数"
      COMMENT = '取引の件数',
    purchase.f_purchase_amount AS "仕入高合計"
      COMMENT = '仕入高の合計金額',
    purchase.f_media_revenue AS "媒体収益合計"
      COMMENT = '媒体収益の実績合計',
    purchase.f_media_budget AS "媒体収益予算合計"
      COMMENT = '媒体収益の予算合計',
    purchase.f_media_variance AS "媒体収益予実差異"
      COMMENT = '媒体収益の予実差異',
    purchase.f_fc_revenue AS "FC営収合計"
      COMMENT = 'FC営業収入の合計',
    purchase.f_staff_cost AS "スタッフコスト合計"
      COMMENT = 'スタッフコストの合計',

    -- 組織損益テーブルのファクト
    special_fee.f_actual AS "実績合計"
      COMMENT = '実績の合計金額',
    special_fee.f_budget AS "予算合計"
      COMMENT = '予算の合計金額',
    special_fee.f_variance AS "予実差異"
      COMMENT = '実績 - 予算の差異',
    special_fee.f_achievement_rate AS "予実達成率"
      COMMENT = '予算達成率（%）'
  )

  -- -------------------------------------------------------
  -- ディメンション（分類カラム = フィルタ・GROUP BY に使用）
  -- -------------------------------------------------------
  DIMENSIONS (
    -- 仕入テーブルのディメンション
    purchase.dim_fiscal_year AS "年度_4月起点"
      WITH SYNONYMS = ('年度', '会計年度', 'FY')
      COMMENT = '4月起点の会計年度',
    purchase.dim_year_month AS "年月"
      WITH SYNONYMS = ('月', 'YYYYMM')
      COMMENT = '年月（YYYYMM形式）',
    purchase.dim_quarter AS "四半期_4月起点"
      WITH SYNONYMS = ('四半期', 'Q', 'クォーター')
      COMMENT = '4月起点の四半期（1Q〜4Q）',
    purchase.dim_sales_company AS "会社_営業_名_最新"
      WITH SYNONYMS = ('営業会社', '会社名')
      COMMENT = '営業担当会社名',
    purchase.dim_industry AS "広告主業種_大名"
      WITH SYNONYMS = ('広告主業種', '業種大分類', '業種')
      COMMENT = '広告主の業種大分類',
    purchase.dim_mass_media AS "マスメディア区分名"
      WITH SYNONYMS = ('マスメディア区分', 'メディア区分')
      COMMENT = 'マスメディアの区分（テレビ、新聞、雑誌、ラジオ等）',
    purchase.dim_media_type AS "媒体種類名"
      WITH SYNONYMS = ('媒体種類', 'メディア種類', '媒体')
      COMMENT = '媒体の種類',
    purchase.dim_agency_key AS AGENCY_KEY
      WITH SYNONYMS = ('代理店系列', '代理店グループ', '系列')
      COMMENT = '代理店系列（H:博報堂, D:大広, Y:読広）',

    -- 組織損益テーブルのディメンション
    special_fee.dim_fee_fiscal_year AS "年度"
      WITH SYNONYMS = ('損益年度')
      COMMENT = '組織損益の会計年度',
    special_fee.dim_fee_year_month AS "年月"
      WITH SYNONYMS = ('損益年月')
      COMMENT = '組織損益の年月（YYYYMM形式）',
    special_fee.dim_fee_quarter AS "四半期"
      WITH SYNONYMS = ('損益四半期')
      COMMENT = '組織損益の四半期',
    special_fee.dim_company AS "会社"
      WITH SYNONYMS = ('グループ会社')
      COMMENT = '会社名（博報堂、大広、博報堂DYメディアパートナーズ等）',
    special_fee.dim_dept_group AS "部門G"
      WITH SYNONYMS = ('部門グループ', '部門G')
      COMMENT = '部門グループ',
    special_fee.dim_department AS "部門"
      WITH SYNONYMS = ('部門名')
      COMMENT = '部門名',
    special_fee.dim_mgmt_item AS "管理項目名称"
      WITH SYNONYMS = ('管理項目', '項目', '損益項目')
      COMMENT = '管理項目名称（売上総利益、コンサルティング収入等）'
  )

  -- -------------------------------------------------------
  -- メトリクス（集計式 = SUMやCASE式で自動計算）
  -- -------------------------------------------------------
  METRICS (
    -- 仕入系メトリクス
    purchase.total_purchase
      AS SUM(purchase.f_purchase_amount)
      WITH SYNONYMS = ('仕入高', '仕入高合計', '仕入')
      COMMENT = '仕入高の合計',
    purchase.total_media_revenue
      AS SUM(purchase.f_media_revenue)
      WITH SYNONYMS = ('媒体収益', '媒体収益合計')
      COMMENT = '媒体収益の合計',
    purchase.total_media_budget
      AS SUM(purchase.f_media_budget)
      WITH SYNONYMS = ('媒体収益予算', '予算')
      COMMENT = '媒体収益の予算合計',
    purchase.budget_achievement_rate
      AS CASE WHEN SUM(purchase.f_media_budget) = 0 THEN NULL
              ELSE ROUND(SUM(purchase.f_media_revenue) * 100.0 / SUM(purchase.f_media_budget), 1) END
      WITH SYNONYMS = ('予実達成率', '達成率')
      COMMENT = '媒体収益の予算達成率（%）',
    purchase.total_deals
      AS SUM(purchase.f_deals)
      WITH SYNONYMS = ('取引件数', '件数')
      COMMENT = '取引件数の合計',
    purchase.total_fc_revenue
      AS SUM(purchase.f_fc_revenue)
      WITH SYNONYMS = ('FC営収', 'FC営業収入')
      COMMENT = 'FC営業収入の合計',
    purchase.total_staff_cost
      AS SUM(purchase.f_staff_cost)
      WITH SYNONYMS = ('スタッフコスト', '人件費')
      COMMENT = 'スタッフコストの合計',
    purchase.revenue_rate
      AS CASE WHEN SUM(purchase.f_purchase_amount) = 0 THEN NULL
              ELSE ROUND(SUM(purchase.f_media_revenue) * 100.0 / SUM(purchase.f_purchase_amount), 2) END
      WITH SYNONYMS = ('収益率', '媒体収益率')
      COMMENT = '仕入高に対する媒体収益の比率（%）',

    -- 組織損益系メトリクス
    special_fee.total_actual
      AS SUM(special_fee.f_actual)
      WITH SYNONYMS = ('実績', '実績合計')
      COMMENT = '実績の合計金額',
    special_fee.total_budget
      AS SUM(special_fee.f_budget)
      WITH SYNONYMS = ('予算合計')
      COMMENT = '予算の合計金額',
    special_fee.total_variance
      AS SUM(special_fee.f_variance)
      WITH SYNONYMS = ('予実差異合計', '差異')
      COMMENT = '予実差異の合計',
    special_fee.fee_achievement_rate
      AS CASE WHEN SUM(special_fee.f_budget) = 0 THEN NULL
              ELSE ROUND(SUM(special_fee.f_actual) * 100.0 / SUM(special_fee.f_budget), 1) END
      WITH SYNONYMS = ('組織損益達成率', '損益達成率')
      COMMENT = '組織損益の予算達成率（%）'
  )

  COMMENT = '博報堂ハンズオン用セマンティックビュー。仕入データ・組織損益データを自然言語で分析するための定義。'

  AI_SQL_GENERATION 'データ期間は2023年4月〜2025年4月（年度は4月起点）。代理店系列のAGENCY_KEYはH=博報堂、D=大広、Y=読広を意味する。金額は円単位で格納されている。purchaseテーブルとspecial_feeテーブルは独立しており結合しない。';

-- ============================================================================
-- Step 5-2: セマンティックビューの確認
-- ============================================================================

-- 作成されたことを確認
SHOW SEMANTIC VIEWS IN SCHEMA HAKUHODO_HANDSON_DB.ANALYTICS;

-- ディメンション一覧の確認
SHOW SEMANTIC DIMENSIONS IN SEMANTIC VIEW HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_SEMANTIC_VIEW;

-- メトリクス一覧の確認
SHOW SEMANTIC METRICS IN SEMANTIC VIEW HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_SEMANTIC_VIEW;

-- ファクト一覧の確認
SHOW SEMANTIC FACTS IN SEMANTIC VIEW HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_SEMANTIC_VIEW;

-- ============================================================================
-- Step 5-3: セマンティックビューを使ったクエリ（動作確認）
-- ============================================================================
-- ★ SEMANTIC_VIEW() 関数を使って、セマンティックビューからデータを取得します。
--   通常の SELECT と異なり、METRICS と DIMENSIONS を指定するだけで
--   適切な集計が行われます。

-- 例1: 年度別の仕入高と媒体収益
SELECT * FROM SEMANTIC_VIEW(
  HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_SEMANTIC_VIEW
  METRICS purchase.total_purchase, purchase.total_media_revenue
  DIMENSIONS purchase.dim_fiscal_year
) ORDER BY dim_fiscal_year;

-- 例2: 媒体種類別の仕入高ランキング
SELECT * FROM SEMANTIC_VIEW(
  HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_SEMANTIC_VIEW
  METRICS purchase.total_purchase, purchase.revenue_rate
  DIMENSIONS purchase.dim_media_type
) ORDER BY total_purchase DESC;

-- 例3: 組織損益 — 会社別の予実達成率
SELECT * FROM SEMANTIC_VIEW(
  HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_SEMANTIC_VIEW
  METRICS special_fee.total_actual, special_fee.total_budget, special_fee.fee_achievement_rate
  DIMENSIONS special_fee.dim_company
) ORDER BY fee_achievement_rate DESC;

-- ============================================================================
-- Step 5-4: Snowflake Intelligence の作成（Snowsight GUI）
-- ============================================================================
-- ★ Snowsight での作成手順:
--
--   1. Snowsight にログイン
--   2. 左メニュー「AI & ML」→「Cortex Analyst」を選択
--   3. 「+ Cortex Analyst」をクリック
--   4. 以下を設定:
--      - Semantic View を選択:
--        HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_SEMANTIC_VIEW
--   5. 「Create」をクリック
--
-- ★ セマンティックビューを使用する場合、YAML アップロードは不要です。
--   GUI から直接セマンティックビューを選択するだけで設定完了です。
-- ============================================================================

-- ============================================================================
-- Step 5-5: Snowflake Intelligence の動作確認
-- ============================================================================
-- ★ Cortex Analyst を開き、以下の質問を試してみましょう:
--
-- 質問例1: 「媒体種類別の仕入高を教えて」
--   → セマンティックビューの METRICS/DIMENSIONS 定義をもとに
--     SQL が自動生成されます
--
-- 質問例2: 「2024年度の予算達成率が最も低い部門は？」
--   → special_fee テーブルの fee_achievement_rate メトリクスが使われます
--
-- 質問例3: 「四半期ごとの仕入高推移をグラフで見せて」
--   → チャート形式で結果が表示されます
--
-- 質問例4: 「博報堂系列の媒体収益はいくら？」
--   → AGENCY_KEY = 'H' でフィルタされます
--     （synonyms で '代理店系列' と定義済みのため認識可能）
--
-- 質問例5: 「収益率が最も高い業種は？」
--   → revenue_rate メトリクス（計算式）が自動適用されます
--
-- ★ 上手くいかない場合のヒント:
--   - 質問に使う用語が synonyms に定義されているか確認
--   - DESCRIBE SEMANTIC VIEW で定義内容を確認可能
--   - ALTER SEMANTIC VIEW で定義の追加・修正が可能

-- セマンティックビューの詳細定義を確認
DESCRIBE SEMANTIC VIEW HAKUHODO_HANDSON_DB.ANALYTICS.HAKUHODO_SEMANTIC_VIEW;

-- ============================================================================
-- ★ 学びのポイント:
--   - セマンティックビューは SQL で定義 → バージョン管理・CI/CD が容易
--   - FACTS: 数値データ、DIMENSIONS: 分類データ、METRICS: 集計式 の3層構造
--   - WITH SYNONYMS で「仕入高」「仕入」など様々な言い回しに対応
--   - AI_SQL_GENERATION でドメイン知識（年度起点、代理店系列コード等）を補完
--   - SEMANTIC_VIEW() 関数で直接クエリ可能（通常の SQL としても利用可能）
--   - 非エンジニアでも自然言語でデータ分析を開始できる
-- ============================================================================
-- 次のステップ: 06_ai_functions.sql に進んでください
-- ============================================================================
