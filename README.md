# Snowflake ハンズオン — 博報堂DYグループ

Snowflake の主要機能を、広告代理店の実業務データを使って体系的に学ぶハンズオンコンテンツです。
データロードからデータエンジニアリング、BI ダッシュボード、AI 分析、Snowflake Intelligence まで、
Snowflake プラットフォームの全レイヤーを一気通貫で体験します。

---

## このハンズオンで学べること

このハンズオンを通じて、以下のスキルを習得できます。

- **データの取り込みと管理**: クラウドストレージからSnowflakeへのデータロード、ウェアハウスサイジングによる性能チューニング、リザルトキャッシュによるコスト最適化
- **データパイプラインの構築**: 命令型（Stream/Task）と宣言型（Dynamic Table）の2つのアプローチを同じデータで比較し、使い分けの判断力を身につける
- **BIダッシュボードの構築**: Snowflake内で完結するStreamlitアプリの開発、Cortex AIを組み込んだ自然言語データ分析
- **AIの業務活用**: SQL内でLLMを直接呼び出すCortex AI Function、ドキュメントのパース・チャンク分割・セマンティック検索、自然言語によるデータ問い合わせ
- **AI エージェントの構築**: 構造化データ（SQL）と非構造化データ（社内ナレッジ）を統合検索できるSnowflake Intelligenceエージェントの設計と構築
- **DevOps連携**: Snowflake上からGitリポジトリを直接参照するGit Integration

---

## ハンズオンのシナリオ

あなたは博報堂DYグループのデータチームに配属されました。
グループ全体の**媒体仕入データ**と**組織損益データ**を活用し、経営層やアカウントチームが意思決定に使えるデータ基盤を Snowflake 上に構築することがミッションです。

**取り扱うデータ:**

| データ | 内容 | 規模 |
|-------|------|------|
| 媒体仕入データ | テレビ・デジタル・新聞等の媒体ごとの仕入高・媒体収益・営収実績 | 約10,000件 |
| 組織損益データ | 会社・部門・管理項目ごとの予算と実績 | 約10,000件 |
| 代理店グループマスタ | 博報堂(H)・大広(D)・読広(Y)の系列コード | 30件 |
| 社内ナレッジ文書 | 仕入ガイドライン・予算管理マニュアル・運用基準等のPDF | 5文書 |

**構築するもの:**

1. **GCS → Snowflake のデータロードパイプライン** — 外部ステージ経由でCSVデータを取り込み
2. **リアルタイム加工パイプライン** — 仕入データと代理店マスタをJOINし、月次集計・予実分析を自動化
3. **BIダッシュボード** — 仕入分析・組織損益・AI問い合わせの3画面構成
4. **Snowflake Intelligence エージェント** — 「先月のデジタル媒体の仕入高は？」「仕入の承認フローを教えて」といった質問に、データ検索とナレッジ検索を組み合わせて回答するAIアシスタント

---

## 学べる Snowflake 機能一覧

### コアプラットフォーム

| 機能 | 概要 | 使用セクション |
|-----|------|--------------|
| Database / Schema / Warehouse | Snowflakeの基本オブジェクト。コンピュートとストレージが完全分離 | Section 0 |
| Warehouse サイズ変更 | WHサイズを変えるだけで処理能力を線形スケール（X-SMALL→MEDIUM で4倍） | Section 1 |
| Result Cache | 同一クエリの2回目以降はWH不使用で即座に結果を返却（クレジット消費ゼロ） | Section 1 |
| Role / 権限管理 | RBAC によるアクセス制御（ACCOUNTADMIN, SYSADMIN 等） | Section 0 |

### データ取り込み

| 機能 | 概要 | 使用セクション |
|-----|------|--------------|
| Storage Integration | クラウドストレージ（GCS/S3/Azure）への認証を管理するオブジェクト | Section 1 |
| External Stage | クラウドストレージのパスを Snowflake のステージとして定義 | Section 1 |
| COPY INTO | ステージ上のファイルをテーブルにバルクロード | Section 1 |
| File Format | CSV/JSON/Parquet 等のファイル形式を定義（区切り文字、ヘッダー、エンコーディング） | Section 1 |

### データエンジニアリング

| 機能 | 概要 | 使用セクション |
|-----|------|--------------|
| Stream | テーブルの変更（INSERT/UPDATE/DELETE）を自動追跡するCDC機構 | Section 2 |
| Task | SQLをスケジュール実行。WHEN句で条件付き実行が可能 | Section 2 |
| Dynamic Table | SELECT文で結果を宣言するだけで、Snowflakeが自動的に増分リフレッシュ | Section 3 |
| TARGET_LAG | Dynamic Tableのリフレッシュ目標遅延を宣言的に指定 | Section 3 |

### AI / ML（Cortex AI）

| 機能 | 概要 | 使用セクション |
|-----|------|--------------|
| CORTEX.COMPLETE | LLMによるテキスト生成。データ分析レポートの自動生成等 | Section 4, 6 |
| CORTEX.SUMMARIZE | テキストの自動要約 | Section 6 |
| CORTEX.TRANSLATE | 多言語翻訳 | Section 6 |
| CORTEX.SENTIMENT | 感情分析（-1.0〜1.0のスコア） | Section 6 |
| CORTEX.EXTRACT_ANSWER | テキストからの質問応答 | Section 6 |
| AI_PARSE_DOCUMENT | PDFからテキストをMarkdown形式で抽出 | Section 5 |
| SPLIT_TEXT_RECURSIVE_CHARACTER | テキストを再帰的にチャンク分割（RAG用前処理） | Section 5 |

### セマンティックレイヤー / 検索 / エージェント

| 機能 | 概要 | 使用セクション |
|-----|------|--------------|
| Semantic View | テーブル・カラムにビジネス上の意味を定義し、自然言語→SQL変換を高精度化 | Section 5 |
| Cortex Search Service | テキストデータに対するセマンティック検索（意味ベースの類似検索） | Section 5 |
| Snowflake Intelligence (Agent) | 複数ツールを統合したAIエージェント。質問に応じてAnalystとSearchを自動選択 | Section 5 |

### アプリケーション / DevOps

| 機能 | 概要 | 使用セクション |
|-----|------|--------------|
| Streamlit in Snowflake | Snowflake内で完結するPythonダッシュボード。データを外部に持ち出さずに可視化 | Section 4 |
| Git Integration | Snowflakeから直接GitHubリポジトリを参照し、ファイルを読み込み | Section 7 |

---

## 全体アーキテクチャ

```
                          ┌─────────────────────────────────────────────────────┐
                          │               Snowflake Platform                    │
                          │                                                     │
  ┌──────────┐            │  ┌───────────────────────────────────────────────┐  │
  │  GCS     │  External  │  │  HAKUHODO_HANDSON_SCHEMA（RAWデータ）          │  │
  │  Bucket  │──Stage────▶│  │  ├─ PURCHASE_NEW_TABLE   (仕入データ)         │  │
  │          │  COPY INTO │  │  ├─ SPECIAL_FEE_TABLE    (組織損益データ)     │  │
  └──────────┘            │  │  └─ MST_AGENCY_GROUP     (代理店マスタ)       │  │
                          │  └───────────┬──────────────────┬────────────────┘  │
                          │              │                  │                    │
                          │        Stream/Task         Dynamic Table            │
                          │        (命令的CDC)          (宣言的変換)             │
                          │              │                  │                    │
                          │  ┌───────────▼──────────────────▼────────────────┐  │
                          │  │  ANALYTICS スキーマ（加工済みデータ）          │  │
                          │  │  ├─ DT_PURCHASE_WITH_AGENCY   (仕入+代理店)  │  │
                          │  │  ├─ DT_PURCHASE_MONTHLY_SUMMARY (月次集計)   │  │
                          │  │  ├─ DT_SPECIAL_FEE_SUMMARY    (損益集計)    │  │
                          │  │  ├─ DT_MONTHLY_AI_REPORT      (AI月次レポ※)│  │
                          │  │  ├─ KNOWLEDGE_CHUNKS           (PDFチャンク) │  │
                          │  │  ├─ HAKUHODO_SEMANTIC_VIEW     (意味定義)   │  │
                          │  │  └─ HAKUHODO_KNOWLEDGE_SEARCH  (検索Service)│  │
                          │  └──────┬────────────┬────────────┬─────────────┘  │
                          │         │            │            │                  │
                          │  ┌──────▼──┐  ┌──────▼──────┐  ┌─▼──────────────┐  │
                          │  │Streamlit│  │ Cortex AI   │  │  Snowflake     │  │
                          │  │  in     │  │ Functions   │  │  Intelligence  │  │
                          │  │Snowflake│  │ (COMPLETE,  │  │  (Agent)       │  │
                          │  │  (SiS)  │  │  SUMMARIZE, │  │  ├─Analyst     │  │
                          │  │         │  │  TRANSLATE,  │  │  └─Search      │  │
                          │  │ 3 Tabs  │  │  SENTIMENT)  │  │                │  │
                          │  └─────────┘  └─────────────┘  └────────────────┘  │
                          └─────────────────────────────────────────────────────┘
```

※ DT_MONTHLY_AI_REPORT は Section 6 (AI Functions) で作成します。

---

## ハンズオンの全体フロー

| Section | SQL ファイル | テーマ | 学べる技術 |
|---------|-------------|--------|-----------|
| 0 | `00_setup.sql` | 環境セットアップ | Database, Schema, Warehouse, Role |
| 1 | `01_external_stage_and_load.sql` | データロード | Storage Integration, External Stage, COPY INTO, WH サイズ比較 |
| 2 | `02_data_engineering_stream_task.sql` | データエンジニアリング（命令型） | Stream (CDC), Task (スケジューラ), 増分パイプライン |
| 3 | `03_data_engineering_dynamic_table.sql` | データエンジニアリング（宣言型） | Dynamic Table, TARGET_LAG, 自動リフレッシュ |
| 4 | `04_streamlit_dashboard.sql` | BI ダッシュボード | Streamlit in Snowflake (SiS), Cortex AI, インタラクティブ可視化 |
| 5 | `05_snowflake_intelligence.sql` | AI エージェント | Semantic View, AI_PARSE_DOCUMENT, Cortex Search, Agent |
| 6 | `06_ai_functions.sql` | AI Function | COMPLETE, SUMMARIZE, TRANSLATE, SENTIMENT, EXTRACT_ANSWER |
| 7 | `07_git_integration.sql` | Git Integration | Git リポジトリ連携, バージョン管理 |

---

## 各セクション詳細

### Section 0: 環境セットアップ (`00_setup.sql`)

ハンズオンで使用する基盤オブジェクトを作成します。

- **HAKUHODO_HANDSON_WH**: X-SMALL ウェアハウス（AUTO_SUSPEND=60s）
- **HAKUHODO_HANDSON_DB**: ハンズオン用データベース
  - **HAKUHODO_HANDSON_SCHEMA**: RAW データ格納用スキーマ
  - **ANALYTICS**: 加工済みデータ格納用スキーマ
  - **STREAMLIT**: ダッシュボードアプリ用スキーマ
- **クロスリージョン推論の有効化**: `CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION'`

**学びのポイント**: Snowflake はコンピュート（WH）とストレージ（DB）が分離しており、それぞれ独立してスケール可能です。

---

### Section 1: データロード (`01_external_stage_and_load.sql`)

GCS（Google Cloud Storage）から Snowflake へデータをロードします。

```
GCS Bucket (hakuhodo_handson/)
  ├─ purchase_new_table/    ──┐
  ├─ special_fee_table/     ──┼── Storage Integration ── External Stage ── COPY INTO
  └─ mst_agency_group/     ──┘
```

**ステップ:**
1. **Storage Integration 作成**: GCS への認証情報を管理するオブジェクト
2. **External Stage 作成**: GCS バケットパスを Snowflake 上のステージとして定義
3. **テーブル作成 & COPY INTO**: CSV を Snowflake テーブルにロード
4. **WH サイズ比較**: X-SMALL → MEDIUM に変更してロード速度の違いを体験

**ロードするデータ:**

| テーブル | 内容 | 件数 |
|---------|------|-----|
| PURCHASE_NEW_TABLE | 媒体仕入データ（年月・媒体種類・業種・金額等） | 約10,000行 |
| SPECIAL_FEE_TABLE | 組織損益データ（会社・部門・予算・実績等） | 約10,000行 |
| MST_AGENCY_GROUP | 代理店グループマスタ（H:博報堂, D:大広, Y:読広） | 約30行 |

**学びのポイント**: Snowflake の WH はサイズ変更だけで処理能力が線形にスケールします。X-SMALL → MEDIUM で約4倍の性能向上が確認できます。

---

### Section 2: データエンジニアリング — Stream / Task (`02_data_engineering_stream_task.sql`)

**命令的（Imperative）** なデータパイプラインを構築します。

```
                     ┌─────────────────────────────────────────┐
                     │         命令的パイプライン                 │
                     │                                         │
 PURCHASE_NEW_TABLE  │  Stream          Task                   │
 ──────────────────▶ │  (変更追跡) ───▶ (INSERT INTO...SELECT)  │ ──▶ PURCHASE_WITH_AGENCY
                     │                  WHEN 差分あり            │     (ANALYTICS スキーマ)
 MST_AGENCY_GROUP    │                  ↑                      │
 ──────────────────▶ │                  JOIN                    │
                     └─────────────────────────────────────────┘
```

**核となる技術:**

- **Stream（変更データキャプチャ）**:
  - テーブルへの INSERT / UPDATE / DELETE を自動追跡
  - `SYSTEM$STREAM_HAS_DATA()` で差分の有無を判定
  - 読み取ると自動的にオフセットが進む（一度処理したデータは再取得されない）

- **Task（スケジュール実行）**:
  - `SCHEDULE = '2 MINUTE'` で定期実行
  - `WHEN SYSTEM$STREAM_HAS_DATA(...)` で差分がある時だけ処理
  - Task の依存関係（親Task → 子Task）でDAGを構成可能

**構築するパイプライン:**

| パイプライン | ソース | 処理内容 | 出力先 |
|------------|--------|---------|--------|
| 仕入+代理店結合 | PURCHASE_NEW_TABLE + MST_AGENCY_GROUP | 仕入データに代理店系列名を JOIN | PURCHASE_WITH_AGENCY |
| 組織損益集計 | SPECIAL_FEE_TABLE | 会社・部門・管理項目別に集計 | SPECIAL_FEE_SUMMARY |

**学びのポイント**: Stream + Task は「どのデータを、いつ、どう処理するか」を明示的に記述する命令型アプローチです。細かい制御が可能ですが、パイプラインが増えると管理が複雑になります。

---

### Section 3: データエンジニアリング — Dynamic Table (`03_data_engineering_dynamic_table.sql`)

**宣言的（Declarative）** なデータパイプラインを構築します。

```
                     ┌─────────────────────────────────────────────────────┐
                     │           宣言的パイプライン（Dynamic Table）         │
                     │                                                     │
 RAW テーブル群       │    DT_PURCHASE_WITH_AGENCY                          │
 ──────────────────▶ │    (TARGET_LAG=2min)                                │
                     │         │                                           │
                     │         └──▶ DT_PURCHASE_MONTHLY_SUMMARY            │
                     │              (TARGET_LAG=2min, 月次集計)              │
                     │                                                     │
 SPECIAL_FEE_TABLE   │    DT_SPECIAL_FEE_SUMMARY                          │
 ──────────────────▶ │    (TARGET_LAG=2min, 予実集計)                       │
                     └─────────────────────────────────────────────────────┘
```

**核となる技術:**

- **Dynamic Table（動的テーブル）**:
  - SELECT 文で「結果の定義」だけを書く（処理手順は書かない）
  - Snowflake がソーステーブルの変更を自動検知し、増分リフレッシュを実行
  - `TARGET_LAG` でリフレッシュの目標遅延を指定（2分、5分、10分等）
  - Dynamic Table 同士の依存関係も自動解決（DAG を自動構築）

**作成する Dynamic Table:**

| Dynamic Table | TARGET_LAG | 処理内容 |
|--------------|-----------|---------|
| DT_PURCHASE_WITH_AGENCY | 2分 | 仕入データ + 代理店マスタ JOIN |
| DT_PURCHASE_MONTHLY_SUMMARY | 2分 | 月次・媒体種類・業種別の集計（SUM, COUNT） |
| DT_SPECIAL_FEE_SUMMARY | 2分 | 会社・部門・管理項目別の予実集計 + 達成率計算 |

**Stream/Task vs Dynamic Table 比較:**

| 観点 | Stream/Task（命令型） | Dynamic Table（宣言型） |
|-----|---------------------|----------------------|
| 記述方法 | INSERT INTO...SELECT + WHEN 条件 | SELECT 文のみ |
| 差分検知 | Stream を明示的に作成・参照 | Snowflake が自動検知 |
| DAG 管理 | Task の依存関係を手動定義 | Dynamic Table 間の参照を自動解決 |
| スケジュール | CRON / 分間隔 で指定 | TARGET_LAG で目標遅延を宣言 |
| 適用場面 | 複雑な条件分岐・外部連携 | 集計・変換・JOIN 等の定型パイプライン |

**学びのポイント**: 同じ結果を生むパイプラインを命令型と宣言型の両方で構築することで、それぞれのメリットを体感できます。実務では Dynamic Table が推奨されるケースが増えています。

---

### Section 4: Streamlit in Snowflake (`04_streamlit_dashboard.sql`)

Snowflake 上で直接動作するインタラクティブ BI ダッシュボードを構築します。

**作成方法**: Snowsight GUI から作成（Projects & Resources → Streamlit → + Streamlit App）

**ダッシュボード構成（3タブ）:**

| タブ | 機能 | 技術要素 |
|-----|------|---------|
| 仕入分析 | 媒体種類別・業種別の仕入高を可視化 | Snowpark DataFrame, st.bar_chart, フィルタ連動 |
| 組織損益分析 | 部門別の予実達成率をモニタリング | KPI メトリクス, 条件付き色分け, 時系列チャート |
| AI 問い合わせ | 自然言語でデータに質問 | Cortex AI (COMPLETE), 7View データ注入, 構造化プロンプト |

**AI 問い合わせタブの仕組み:**

```
ユーザーの質問
     │
     ▼
7つの集計SQLを実行（年度別KPI, 媒体種類別, 業種別, 四半期推移 等）
     │
     ▼
取得した実データをプロンプトに注入
     │
     ▼
Cortex AI (claude-4-sonnet) に送信
     │
     ▼
構造化された分析レポート（結論・数値根拠・比較分析・ビジネス示唆）
```

**学びのポイント**: Streamlit in Snowflake はデータを外部に持ち出すことなく、Snowflake 内でダッシュボードを構築・共有できます。Cortex AI を組み合わせることで、データ分析とAI推論をシームレスに統合できます。

---

### Section 5: Snowflake Intelligence (`05_snowflake_intelligence.sql`)

セマンティックビュー、Cortex Search、Snowflake Intelligence（Agent）を構築し、
構造化データと非構造化データを統合的に検索・分析できる AI エージェントを作成します。

**構築フロー:**

```
Step 5-1〜5-5: セマンティックビュー
  HAKUHODO_SEMANTIC_VIEW
  ├─ TABLES: purchase, special_fee（論理名・同義語・コメント）
  ├─ FACTS: 11項目（仕入高, 媒体収益, 予算 等）
  ├─ DIMENSIONS: 15項目（年度, 媒体種類, 業種, 代理店系列 等）
  ├─ METRICS: 12項目（合計, 達成率, 収益率 等の計算式）
  └─ AI_SQL_GENERATION: ドメイン知識（年度起点, 代理店コード 等）

Step 5-6〜5-9: Cortex Search
  PDFアップロード ──▶ AI_PARSE_DOCUMENT ──▶ SPLIT_TEXT_RECURSIVE_CHARACTER ──▶ KNOWLEDGE_CHUNKS ──▶ HAKUHODO_KNOWLEDGE_SEARCH
  (5文書)           (Markdown抽出)         (1500トークン/300オーバーラップ)    (チャンクテーブル)     (Cortex Search Service)

Step 5-10: Snowflake Intelligence (Agent)
  HAKUHODO_INTELLIGENCE
  ├─ Tool 1: DataAnalyst (cortex_analyst_text_to_sql) → HAKUHODO_SEMANTIC_VIEW
  └─ Tool 2: KnowledgeSearch (cortex_search) → HAKUHODO_KNOWLEDGE_SEARCH
```

**核となる技術:**

- **Semantic View（セマンティックビュー）**: テーブル・カラムに「ビジネス上の意味」を SQL で定義。FACTS（数値）/ DIMENSIONS（分類）/ METRICS（集計式）の3層構造で、Cortex Analyst が自然言語から正確な SQL を生成可能にする
- **AI_PARSE_DOCUMENT**: PDF からテキストを Markdown 形式で抽出する Cortex AI 関数
- **SPLIT_TEXT_RECURSIVE_CHARACTER**: テキストを再帰的にチャンク分割する関数。段落→改行→空白の順にセパレータを試行し、意味のある単位で分割
- **Cortex Search Service**: テキストデータに対するセマンティック検索（意味ベース検索）を提供。キーワード一致ではなく意味的に近い内容を検索
- **Agent (Snowflake Intelligence)**: 複数ツールを統合した AI エージェント。質問の内容に応じて Cortex Analyst（構造化データ）と Cortex Search（ナレッジ）を自動選択

**サンプルナレッジドキュメント（5文書）:**

| ファイル | 内容 |
|---------|------|
| 01_媒体仕入ガイドライン.pdf | メディアバイイングのルール・承認フロー・リスク管理 |
| 02_予算管理マニュアル.pdf | 予実管理の方法・差異分析・フォーキャスト |
| 03_デジタル広告運用基準.pdf | デジタル広告の KPI 体系・プラットフォーム別運用ルール |
| 04_広告主業種別営業戦略.pdf | 業種別の市場動向とアプローチガイド |
| 05_新入社員向けSnowflake活用ガイド.pdf | 社内データ分析基盤の使い方入門 |

---

### Section 6: AI Functions (`06_ai_functions.sql`)

SQL の中で直接 LLM を呼び出す Cortex AI Function の活用例を学びます。

| 関数 | 用途 | 例 |
|-----|------|-----|
| `CORTEX.COMPLETE` | テキスト生成・データ分析 | 月次仕入データの自動分析レポート生成 |
| `CORTEX.SUMMARIZE` | テキスト要約 | 長文レポートの要点抽出 |
| `CORTEX.TRANSLATE` | 多言語翻訳 | 日本語レポートの英語翻訳 |
| `CORTEX.SENTIMENT` | 感情分析 | テキストのポジネガ判定（-1.0〜1.0） |
| `CORTEX.EXTRACT_ANSWER` | 質問応答 | テキストから特定の回答を抽出 |

**使用モデル**: `claude-4-sonnet`

**応用例 — AI × Dynamic Table:**

このセクションでは `DT_MONTHLY_AI_REPORT` という Dynamic Table を作成します。
DT_PURCHASE_MONTHLY_SUMMARY（Section 3 で作成）をソースに、Cortex AI (`COMPLETE`) で月次仕入データの自動分析レポートを生成します。
データが更新されるたびに AI レポートも自動リフレッシュされる、AI をパイプラインに組み込んだ応用例です。

**学びのポイント**: AI Function は SQL のパイプライン（Dynamic Table, Task 等）に直接組み込めるため、ETL の一部として AI 処理を自動化できます。

---

### Section 7: Git Integration (`07_git_integration.sql`)

Snowflake から直接 GitHub リポジトリを参照し、ファイルを読み込む仕組みを構築します。

**学びのポイント**: Git Integration により、SQL スクリプトやステージファイルのバージョン管理を Snowflake 上で一元化できます。

---

## ディレクトリ構成

```
hakuhodo-snowflake-handson/
├── README.md                              このファイル
├── generate_data.py                       サンプル CSV データ生成スクリプト
├── generate_knowledge_pdf.py              サンプルナレッジ PDF 生成スクリプト
├── data/                                  サンプル CSV データ
│   ├── purchase_new_table/                仕入 RAW データ（4ファイル x 2,500行）
│   ├── special_fee_table/                 組織損益 RAW データ（4ファイル x 2,500行）
│   └── mst_agency_group/                  代理店グループマスタ（2ファイル x 15行）
├── knowledge_docs/                        サンプルナレッジ PDF（5文書）
│   ├── 01_媒体仕入ガイドライン.pdf
│   ├── 02_予算管理マニュアル.pdf
│   ├── 03_デジタル広告運用基準.pdf
│   ├── 04_広告主業種別営業戦略.pdf
│   └── 05_新入社員向けSnowflake活用ガイド.pdf
├── sql/                                   ハンズオン SQL スクリプト
│   ├── 00_setup.sql                       環境セットアップ
│   ├── 01_external_stage_and_load.sql     GCS 外部ステージ & データロード
│   ├── 02_data_engineering_stream_task.sql Stream / Task パイプライン
│   ├── 03_data_engineering_dynamic_table.sql Dynamic Table パイプライン
│   ├── 04_streamlit_dashboard.sql         Streamlit in Snowflake（GUI作成手順）
│   ├── 05_snowflake_intelligence.sql      Semantic View + Cortex Search + Agent
│   ├── 06_ai_functions.sql                Cortex AI Function 活用例
│   └── 07_git_integration.sql             Git Integration セットアップ
└── streamlit/
    └── hakuhodo_dashboard.py              Streamlit ダッシュボードアプリ本体
```

---

## 前提条件

- Snowflake アカウント（SYSADMIN / ACCOUNTADMIN ロール）
- GCS バケット（外部ステージ用）または Git リポジトリ経由でのデータロード
- クロスリージョン推論の有効化（Section 0 で設定）

## Snowflake 環境情報

| 項目 | 値 |
|------|-----|
| Database | `HAKUHODO_HANDSON_DB` |
| RAW Schema | `HAKUHODO_HANDSON_SCHEMA` |
| Analytics Schema | `ANALYTICS` |
| Streamlit Schema | `STREAMLIT` |
| Warehouse | `HAKUHODO_HANDSON_WH` (X-SMALL) |
| AI Model | `claude-4-sonnet` |
| GCS Bucket | `hakuhodo_handson` |

## 実行順序

```
00_setup.sql                          環境セットアップ
    │
07_git_integration.sql                Git Integration（Git経由でロードする場合）
    │
01_external_stage_and_load.sql        データロード + WH サイズ比較
    │
    ├── 02_data_engineering_stream_task.sql    Stream/Task パイプライン
    │
    └── 03_data_engineering_dynamic_table.sql  Dynamic Table パイプライン
            │
            ├── 04_streamlit_dashboard.sql     BI ダッシュボード構築
            │
            ├── 05_snowflake_intelligence.sql  Semantic View + Cortex Search + Agent
            │
            └── 06_ai_functions.sql            AI Function 活用例
```
