#!/usr/bin/env python3
"""
博報堂ハンズオン用 サンプルナレッジPDF生成スクリプト

Cortex Search で検索可能な内部ナレッジドキュメント（5文書）を生成します。
生成先: knowledge_docs/ ディレクトリ

使い方:
  python3 generate_knowledge_pdf.py

前提:
  pip install fpdf2
"""

import os
from fpdf import FPDF

# macOS Hiragino Sans GB (日本語対応)
FONT_PATH = "/System/Library/Fonts/Hiragino Sans GB.ttc"
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "knowledge_docs")


class JapanesePDF(FPDF):
    """日本語対応PDFクラス"""

    def __init__(self):
        super().__init__()
        self.add_font("JP", "", FONT_PATH)
        self.add_font("JP", "B", FONT_PATH)

    def header(self):
        self.set_font("JP", "B", 10)
        self.set_text_color(120, 120, 120)
        self.cell(0, 8, "博報堂DYグループ 社内ナレッジ（サンプル）", align="R", new_x="LMARGIN", new_y="NEXT")
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(4)

    def footer(self):
        self.set_y(-15)
        self.set_font("JP", "", 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 10, f"Page {self.page_no()}/{{nb}}", align="C")

    def title_page(self, title, subtitle, date):
        self.add_page()
        self.ln(60)
        self.set_font("JP", "B", 24)
        self.set_text_color(0, 51, 102)
        self.multi_cell(0, 14, title, align="C")
        self.ln(10)
        self.set_font("JP", "", 14)
        self.set_text_color(80, 80, 80)
        self.multi_cell(0, 10, subtitle, align="C")
        self.ln(20)
        self.set_font("JP", "", 11)
        self.set_text_color(100, 100, 100)
        self.cell(0, 8, f"作成日: {date}", align="C", new_x="LMARGIN", new_y="NEXT")
        self.cell(0, 8, "博報堂DYグループ 経営企画本部", align="C")

    def section(self, title):
        self.ln(6)
        self.set_font("JP", "B", 14)
        self.set_text_color(0, 51, 102)
        self.cell(0, 10, title, new_x="LMARGIN", new_y="NEXT")
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(4)
        self.set_text_color(0, 0, 0)

    def subsection(self, title):
        self.ln(3)
        self.set_font("JP", "B", 11)
        self.set_text_color(51, 51, 102)
        self.cell(0, 8, title, new_x="LMARGIN", new_y="NEXT")
        self.ln(2)
        self.set_text_color(0, 0, 0)

    def body(self, text):
        self.set_font("JP", "", 10)
        self.multi_cell(0, 6, text)
        self.ln(2)

    def bullet(self, text):
        self.set_font("JP", "", 10)
        x = self.get_x()
        self.cell(8, 6, "・")
        self.multi_cell(0, 6, text)


def doc1_media_buying_guideline():
    """媒体仕入ガイドライン"""
    pdf = JapanesePDF()
    pdf.alias_nb_pages()
    pdf.title_page(
        "媒体仕入ガイドライン",
        "メディアバイイングにおける標準手順と判断基準",
        "2024年4月 改訂版",
    )

    pdf.add_page()
    pdf.section("1. 本ガイドラインの目的")
    pdf.body(
        "本ガイドラインは、博報堂DYグループにおける媒体仕入業務の標準化と品質向上を目的とする。"
        "テレビ、新聞、雑誌、ラジオ、デジタル等の各メディアにおける仕入判断基準、承認フロー、"
        "リスク管理の方法を定める。全社員がこのガイドラインに基づき、一貫した基準で仕入業務を遂行すること。"
    )

    pdf.section("2. 媒体種類別の仕入基準")
    pdf.subsection("2-1. テレビ媒体")
    pdf.body(
        "テレビスポットの仕入れは、GRP（延べ視聴率）単価を基準とする。"
        "関東キー局の場合、プライムタイム（19:00-23:00）のGRP単価は業種・シーズンにより変動するが、"
        "前年同期比+10%を超える場合は部長承認が必要。"
        "番組提供（タイム）は、視聴率実績・ターゲットリーチ・ブランドセーフティを総合評価する。"
        "新番組への出稿は初回3クール以内の撤退条件を契約に含めること。"
    )
    pdf.subsection("2-2. 新聞・雑誌媒体")
    pdf.body(
        "新聞は段単価、雑誌はページ単価を基準とする。"
        "全国紙の全面広告は1,000万円以上となるため、本部長承認が必要。"
        "地方紙は地域カバレッジとCPM（千人あたりコスト）の両面から評価する。"
        "雑誌の場合、発行部数の実績（ABC公査データ）を確認し、公称部数との乖離が20%以上の場合は要注意。"
    )
    pdf.subsection("2-3. デジタル媒体")
    pdf.body(
        "デジタル広告はCPC（クリック単価）、CPM（千インプレッション単価）、CPA（獲得単価）の"
        "3指標で評価する。プログラマティック取引では、ビューアビリティ率60%以上、"
        "ブランドセーフティスコア90%以上を最低基準とする。"
        "年間取引額5,000万円以上のプラットフォームとは個別の取引条件交渉を行うこと。"
    )

    pdf.section("3. 承認フローと決裁基準")
    pdf.body(
        "仕入金額に応じた承認権限は以下の通り:\n"
        "  - 500万円未満: 担当チームリーダー承認\n"
        "  - 500万円以上 3,000万円未満: 部長承認\n"
        "  - 3,000万円以上 1億円未満: 本部長承認\n"
        "  - 1億円以上: 役員承認（経営会議付議）\n\n"
        "緊急案件（クライアント起因で48時間以内の対応が必要な場合）は、"
        "事後承認を認めるが、翌営業日中に正式な承認手続きを完了すること。"
    )

    pdf.section("4. リスク管理")
    pdf.body(
        "媒体仕入におけるリスクは、価格リスク・在庫リスク・与信リスクの3つに分類される。"
        "四半期ごとにリスク評価を実施し、仕入先の財務状況・市場動向を踏まえた見直しを行う。"
        "特に、年度末（3月）は予算消化による仕入集中が発生しやすいため、"
        "2月末までに年度内の発注見込みを確定させること。"
    )

    return pdf, "01_媒体仕入ガイドライン.pdf"


def doc2_budget_management_manual():
    """予算管理マニュアル"""
    pdf = JapanesePDF()
    pdf.alias_nb_pages()
    pdf.title_page(
        "予算管理マニュアル",
        "予実管理の方法・承認フロー・差異分析の手引き",
        "2024年4月 改訂版",
    )

    pdf.add_page()
    pdf.section("1. 予算管理の基本方針")
    pdf.body(
        "博報堂DYグループの会計年度は4月起点（4月〜翌3月）である。"
        "予算は年度開始前の2月に確定し、四半期ごとにローリング予測（フォーキャスト）を更新する。"
        "予算と実績の差異が10%を超える場合は、差異分析レポートの提出が義務付けられる。"
    )

    pdf.section("2. 予算策定プロセス")
    pdf.subsection("2-1. スケジュール")
    pdf.body(
        "10月: 次年度の市場見通し・方針共有（経営企画本部）\n"
        "11月: 各部門のボトムアップ予算策定開始\n"
        "12月: 部門予算の一次集計・調整会議\n"
        "1月: 全社予算の調整・最終化\n"
        "2月: 取締役会承認\n"
        "3月: 各部門へ配賦・システム登録"
    )
    pdf.subsection("2-2. 予算の構成要素")
    pdf.body(
        "予算は以下の項目で構成される:\n"
        "  - 売上総利益（グロスプロフィット）\n"
        "  - 媒体収益（メディアコミッション + バイインググロス）\n"
        "  - FC営業収入（フィー・コミッション型収入）\n"
        "  - スタッフコスト（人件費 + 外注費）\n"
        "  - 特別費（販促費、研修費、システム投資等）\n\n"
        "各項目は会社・部門グループ・部門の3階層で管理する。"
    )

    pdf.section("3. 予実管理と差異分析")
    pdf.subsection("3-1. 月次レビュー")
    pdf.body(
        "毎月10営業日目までに前月の実績を確定し、予算との差異を算出する。"
        "差異率（=(実績-予算)/予算×100）が以下の基準を超える場合はアクション必須:\n"
        "  - ±5%以内: 正常範囲（報告のみ）\n"
        "  - ±5%超〜10%: 要注意（差異理由の記載必須）\n"
        "  - ±10%超: 要改善（改善計画の提出必須）\n"
        "  - ±20%超: 緊急対応（臨時経営会議で報告）"
    )
    pdf.subsection("3-2. 差異分析の視点")
    pdf.body(
        "差異分析は以下の多角的な視点で行う:\n"
        "  1. 数量差異: 取引件数の増減による影響\n"
        "  2. 単価差異: 媒体単価の変動による影響\n"
        "  3. ミックス差異: 媒体種類構成比の変化による影響\n"
        "  4. 為替差異: 海外媒体の為替変動による影響（該当する場合）\n"
        "  5. タイミング差異: 計上月のずれによる一時的な差異"
    )

    pdf.section("4. フォーキャスト（ローリング予測）")
    pdf.body(
        "四半期ごとに年度末着地見込みを更新する。"
        "フォーキャストは実績＋残期間見込みで算出し、当初予算との乖離要因を明確にする。"
        "Q2終了時点（9月末）のフォーキャストが予算比マイナス15%を超える場合は、"
        "年度後半のコスト削減施策を経営会議で決定する。"
    )

    return pdf, "02_予算管理マニュアル.pdf"


def doc3_digital_ad_standards():
    """デジタル広告運用基準"""
    pdf = JapanesePDF()
    pdf.alias_nb_pages()
    pdf.title_page(
        "デジタル広告運用基準",
        "デジタル広告のKPI設定・運用ルール・レポーティング基準",
        "2024年7月 制定",
    )

    pdf.add_page()
    pdf.section("1. デジタル広告のKPI体系")
    pdf.body(
        "デジタル広告の効果測定は、ファネルの各段階に対応したKPIで管理する。"
    )
    pdf.subsection("1-1. 認知段階（Upper Funnel）")
    pdf.body(
        "  - インプレッション数: 広告の表示回数\n"
        "  - リーチ数: ユニークユーザー到達数\n"
        "  - CPM（千インプレッション単価）: 目安 300円〜1,500円（媒体・業種による）\n"
        "  - ブランドリフト: 認知度・好意度の変化（調査ベース）\n"
        "  - ビューアビリティ率: 60%以上を最低基準とする"
    )
    pdf.subsection("1-2. 検討段階（Middle Funnel）")
    pdf.body(
        "  - クリック数・CTR（クリック率）: 目安 0.1%〜2.0%\n"
        "  - CPC（クリック単価）: 目安 30円〜500円\n"
        "  - サイト滞在時間: 平均60秒以上を目標\n"
        "  - 動画完全視聴率（VTR）: 目安 30%〜70%"
    )
    pdf.subsection("1-3. 行動段階（Lower Funnel）")
    pdf.body(
        "  - コンバージョン数（CV）: 購入・申込・資料請求等\n"
        "  - CPA（獲得単価）: クライアント業種別の上限を設定\n"
        "  - ROAS（広告費用対効果）: 300%以上を推奨基準\n"
        "  - LTV（顧客生涯価値）対比での投資判断"
    )

    pdf.section("2. プラットフォーム別運用ルール")
    pdf.subsection("2-1. Google広告")
    pdf.body(
        "検索連動型広告はキーワード品質スコア6以上を維持する。"
        "品質スコアが4以下のキーワードは停止または改善対象。"
        "自動入札戦略（Target CPA, Maximize Conversions等）の導入を原則とするが、"
        "新規出稿の最初の2週間は手動入札で初期データを蓄積すること。"
        "ディスプレイネットワークでの配信面は、カテゴリ除外とプレースメント除外を必ず設定する。"
    )
    pdf.subsection("2-2. Meta広告（Facebook/Instagram）")
    pdf.body(
        "Advantage+ キャンペーンの活用を推奨。ただし、ブランドセーフティの観点から"
        "配信面の事後チェックを週次で実施する。"
        "クリエイティブは3〜5パターンを同時テストし、2週間ごとに成果の悪いものを差し替える。"
        "オーディエンスの重複率が30%を超えるキャンペーンは統合を検討する。"
    )

    pdf.section("3. レポーティング基準")
    pdf.body(
        "デジタル広告のレポートは以下の頻度・粒度で作成する:\n\n"
        "  日次レポート: 配信量・コスト・主要KPIのサマリー（自動化推奨）\n"
        "  週次レポート: パフォーマンス分析・改善アクション記載\n"
        "  月次レポート: 目標対比・前月比・施策効果の総括\n"
        "  四半期レポート: 戦略レビュー・次四半期施策提案\n\n"
        "全レポートはSnowflakeのダッシュボード（Streamlit in Snowflake）で"
        "リアルタイム閲覧可能な形式を目指す。"
    )

    return pdf, "03_デジタル広告運用基準.pdf"


def doc4_industry_sales_strategy():
    """広告主業種別営業戦略"""
    pdf = JapanesePDF()
    pdf.alias_nb_pages()
    pdf.title_page(
        "広告主業種別営業戦略",
        "主要業種の市場動向と営業アプローチガイド",
        "2024年10月 更新版",
    )

    pdf.add_page()
    pdf.section("1. 業種別市場概況（2024年度）")
    pdf.body(
        "日本の広告市場は2024年に約7.5兆円規模に達し、デジタル広告がその約45%を占める。"
        "博報堂DYグループとして特に注力する業種と、各業種の広告投資トレンドを整理する。"
    )

    pdf.subsection("1-1. 自動車業種")
    pdf.body(
        "EV（電気自動車）シフトに伴い、従来のテレビCM中心からデジタル+体験型イベントへ"
        "予算移行が加速。特にYouTube・TikTokでのショートムービー活用が増加。"
        "年間広告費: 業界全体で約5,000億円、うちデジタル比率は約35%。"
        "博報堂DYグループのシェア: 約18%（業界3位）。"
        "営業戦略: データドリブンなカスタマージャーニー提案で差別化。"
        "Snowflakeを活用した広告効果の統合分析を提案ポイントとする。"
    )
    pdf.subsection("1-2. 食品・飲料業種")
    pdf.body(
        "健康志向・サステナビリティ関連商品の広告が増加傾向。"
        "テレビCMの比率は依然高い（約40%）が、SNS発のバズマーケティング事例も増加。"
        "年間広告費: 業界全体で約6,000億円。"
        "博報堂DYグループのシェア: 約22%（業界2位）。"
        "営業戦略: 生活者データ（生活定点調査）を活用したインサイト提案。"
    )
    pdf.subsection("1-3. 情報通信業種")
    pdf.body(
        "5Gサービス拡大に伴う通信キャリアの広告費は堅調。"
        "SaaS企業のBtoB広告が急成長しており、リード獲得型施策のニーズが高い。"
        "年間広告費: 業界全体で約8,000億円。"
        "博報堂DYグループのシェア: 約15%。"
        "営業戦略: ABM（アカウントベースドマーケティング）ソリューションの提案。"
    )

    pdf.section("2. 業種横断の営業ナレッジ")
    pdf.subsection("2-1. 提案時の基本フレームワーク")
    pdf.body(
        "クライアントへの提案は以下のフレームワークに基づく:\n"
        "  1. 市場環境分析: 業界トレンド・競合動向・消費者インサイト\n"
        "  2. 課題定義: クライアントのビジネスKPIとの接続\n"
        "  3. 戦略方向性: コミュニケーション戦略の大方針\n"
        "  4. メディアプラン: 最適なメディアミックスの提案\n"
        "  5. 効果予測: Snowflake上のデータを活用したシミュレーション\n"
        "  6. 投資対効果: ROAS・ブランドリフト等の効果測定設計"
    )
    pdf.subsection("2-2. クロスセルの推進")
    pdf.body(
        "既存クライアントへのクロスセル率を高めることが収益拡大の鍵。"
        "現在テレビのみのクライアントにはデジタル施策を、デジタルのみには"
        "OOH（屋外広告）やイベントを提案する。"
        "仕入データ分析により、媒体種類の偏りがあるクライアントを自動抽出し、"
        "提案機会リストを四半期ごとに更新する。"
    )

    return pdf, "04_広告主業種別営業戦略.pdf"


def doc5_snowflake_guide():
    """新入社員向けSnowflake活用ガイド"""
    pdf = JapanesePDF()
    pdf.alias_nb_pages()
    pdf.title_page(
        "新入社員向け\nSnowflake活用ガイド",
        "社内データ分析基盤の使い方入門",
        "2024年4月 初版",
    )

    pdf.add_page()
    pdf.section("1. Snowflakeとは")
    pdf.body(
        "Snowflakeは博報堂DYグループが採用しているクラウドデータプラットフォームです。"
        "従来のオンプレミスDWH（データウェアハウス）と異なり、以下の特徴があります:\n"
        "  - クラウドネイティブ: サーバー管理不要、必要な時に必要なリソースを利用\n"
        "  - コンピュートとストレージの分離: コスト効率が高い\n"
        "  - ニアゼロメンテナンス: インデックス設計やチューニングが不要\n"
        "  - データ共有: 部門間・グループ会社間でセキュアにデータを共有可能\n"
        "  - AI/ML統合: Cortex AI で自然言語によるデータ分析が可能"
    )

    pdf.section("2. 社内データの構成")
    pdf.subsection("2-1. データベース構成")
    pdf.body(
        "社内のSnowflake環境には以下の主要データベースがあります:\n"
        "  - HAKUHODO_HANDSON_DB: ハンズオン・研修用データベース\n"
        "    - HAKUHODO_HANDSON_SCHEMA: 生データ（CSVインポート先）\n"
        "    - ANALYTICS: 加工済みデータ（Dynamic Table）\n"
        "    - STREAMLIT: ダッシュボードアプリ用\n\n"
        "生データは定期的にGCS（Google Cloud Storage）から自動連携されます。"
    )
    pdf.subsection("2-2. 主要テーブル")
    pdf.body(
        "分析で使用する主なテーブル:\n"
        "  - DT_PURCHASE_MONTHLY_SUMMARY: 月次仕入集計データ\n"
        "    → 媒体種類別・業種別・代理店系列別の仕入高・収益を月単位で確認\n"
        "  - DT_SPECIAL_FEE_SUMMARY: 組織損益集計データ\n"
        "    → 会社・部門別の予算と実績を管理項目ごとに確認\n"
        "  - DT_PURCHASE_WITH_AGENCY: 代理店系列付き仕入詳細データ\n"
        "  - DT_MONTHLY_AI_REPORT: AIが生成する月次分析レポート"
    )

    pdf.section("3. Snowflake Intelligence の使い方")
    pdf.body(
        "Snowflake Intelligence は、自然言語でデータに問い合わせできる機能です。"
        "SQLを書かなくても、日本語で質問するだけでデータを取得・分析できます。"
    )
    pdf.subsection("3-1. アクセス方法")
    pdf.body(
        "  1. Snowsight（Webブラウザ）にログイン\n"
        "  2. 左メニュー「AI & ML」→「Snowflake Intelligence」を選択\n"
        "  3. 「HAKUHODO_INTELLIGENCE」を選択\n"
        "  4. チャット画面で質問を入力"
    )
    pdf.subsection("3-2. 質問の例")
    pdf.body(
        "構造化データに関する質問（Cortex Analyst が回答）:\n"
        "  - 「2024年度の媒体種類別仕入高を教えて」\n"
        "  - 「予算達成率が最も低い部門は？」\n"
        "  - 「博報堂系列の四半期ごとの仕入高推移は？」\n\n"
        "ナレッジに関する質問（Cortex Search が回答）:\n"
        "  - 「仕入の承認フローはどうなっていますか？」\n"
        "  - 「デジタル広告のKPI基準を教えて」\n"
        "  - 「食品業界の営業戦略のポイントは？」"
    )

    pdf.section("4. Streamlit ダッシュボードの使い方")
    pdf.body(
        "Streamlit in Snowflake（SiS）で構築された社内ダッシュボードでは、"
        "インタラクティブにデータを可視化できます。\n\n"
        "アクセス方法:\n"
        "  1. Snowsight にログイン\n"
        "  2. 左メニュー「Projects & Resources」→「Streamlit」を選択\n"
        "  3. 「HAKUHODO_DASHBOARD」をクリック\n\n"
        "ダッシュボードには3つのタブがあります:\n"
        "  - 仕入分析: 媒体種類別・業種別の仕入高を可視化\n"
        "  - 組織損益分析: 部門別の予実達成率をモニタリング\n"
        "  - AI問い合わせ: 自然言語でデータに質問（Cortex AI活用）"
    )

    return pdf, "05_新入社員向けSnowflake活用ガイド.pdf"


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    generators = [
        doc1_media_buying_guideline,
        doc2_budget_management_manual,
        doc3_digital_ad_standards,
        doc4_industry_sales_strategy,
        doc5_snowflake_guide,
    ]

    for gen in generators:
        pdf, filename = gen()
        filepath = os.path.join(OUTPUT_DIR, filename)
        pdf.output(filepath)
        print(f"生成完了: {filepath}")

    print(f"\n全{len(generators)}文書を {OUTPUT_DIR} に生成しました。")


if __name__ == "__main__":
    main()
