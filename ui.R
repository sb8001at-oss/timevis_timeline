ui <- page_sidebar(
  theme = bs_theme(bootswatch = "minty"),
  title = "タイムライン作成",
  sidebar = sidebar(  
    card(
      card_header(
        "タイムラインをアップロードする"
      ),
      card_body(
        fileInput("TL_file", NULL, accept=".Rdata")
      )
      
    ),
    
    card(
      card_header("タイムラインのタイトル"),
      card_body(
        textInput("title_in", NULL, value = "タイトル")
      )
    ),
  
    card(
      max_height = 300,
      card_header(
        "アイテムを追加する"
      ),
      card_body(
        textInput("name_item", "項目名", value = "XXX"),
        dateInput("date_start", "開始日", value = Sys.Date()), 
        dateInput("date_end", "終了日", value = Sys.Date()+months(1)),
        selectInput(
          "type_item",
          "タイプ",
          choices = c("box", "range", "point"),
          selected = "range"
        ),
        uiOutput("group_names_input"),
        actionButton("add_TL", "アイテム追加")
      )
    ),

    card(
      max_height = 300,
      card_header(
        "グループを追加する"
      ),
      card_body(
        textInput("name_new_group", "グループ名", value = "YYY"),
        selectInput(
          "style_new_group",
          "グループの色",
          choices = names(group_style),
          selected = names(group_style)[1]
        ),
        splitLayout(
          htmlOutput("css_group_image"),
          htmlOutput("css_TL_image")        
        ),
        actionButton("add_group", "グループ追加")
      )
    ),
    card(
      card_header("グループを削除する"),
      card_body(
        uiOutput("group_names_input"),
        actionButton("delete_group", "グループ削除")
      )
    ),
    tags$a(href = "https://github.com/sb8001at_oss/timevis_timeline", icon("github"))
  ),  
  
  navset_tab(
    nav_panel(
      title = "タイムライン", 
      h5(textOutput("title_out")),
      timevisOutput("vistimeline"),
      actionButton("go", "スクリーンショット")
    ),

    nav_panel(
      title = "詳細データ", 
      layout_columns(
        col_widths = c(1, 11),
        card(
          card_header("タイムラインデータを保存する"), 
          card_body(downloadButton("downloadData", "ダウンロード"))
        ),
        
        card(card_header("タイムラインの情報"), card_body(tableOutput("TL_table")))
      ),
      
      layout_columns(
        col_widths = c(1, 11),
        
        card(
          card_header("Excelファイルを出力する"),
          card_body(
            selectInput("timespan_selected", "出力の間隔", choices = c("月", "週", "日"), selected = "月"),
            downloadButton("downloadExcel", "ダウンロード")
          )
        ),
        
        card(card_header("グループの情報"), card_body(tableOutput("group_table")))
      )
    ),
    nav_panel(
      title = "使い方について",
      br(),
      h1("タイムラインの作成・保存の方法について"),
      p("以下に、このアプリの使い方を説明します。"),
      h3("このアプリについて"),
      p(
        "このアプリはShinyというWebアプリケーション作成ソフトウェアを用いて作成しました。
      このWebアプリはあなたのPCのブラウザの演算能力を用いて動いています。
      ですので、Webを通じてファイルをインターネットにアップロードすることはありません。"
      ),
      hr(),
      h3("タイムラインにタイトルをつける"),
      p("タイムラインのタイトルは、左に表示されている「タイムラインのタイトル」の部分に入力します。"),
      tags$img(src = "card_title.png", title = "タイムラインのタイトル"),
      p("タイムラインのタイトル"),
      hr(),
      h3("タイムラインの操作"),
      p("タイムラインには、左上にタイトル、タイムラインにはグループとイベント、その下に日時が表示されます。"),
      tags$img(src = "timeline_example.png", title = "タイムラインの表示例"),
      p("タイムラインの表示例"),
      hr(),
      h5("タイムラインの拡大・縮小"),
      p("このタイムライン上でマウスのホイールを回転させるとタイムラインを拡大・縮小することができます。"),
      tags$img(src = "timeline_zoomout.png", title = "タイムラインの拡大・縮小"),
      p("タイムラインの拡大・縮小"),
      hr(),
      h5("タイムラインの移動"),
      p("タイムライン上でドラッグすると、タイムラインの位置を移動させることができます。"),
      tags$img(src = "timeline_move.png", title = "タイムラインの移動"),
      p("タイムラインの移動"),
      hr(),
      h5("イベントの選択"),
      HTML("<p>タイムライン上のイベントは選択することができます。選択すると、右側に赤色の<span style=\"color: red; font-weight: bold;\">×</span>が表示されます。</p>"),
      tags$img(src = "timeline_select.png", title = "イベントの選択"),
      p("イベントの選択"),
      hr(),
      h5("複数イベントの選択"),
      p("Ctrlを押しながらイベントを選択すると、複数のイベントを選択することができます。"),
      tags$img(src = "timeline_multiselect.png", title = "複数イベントの選択"),
      p("複数イベントの選択"),
      hr(),
      h5("イベントの移動"),
      p("イベントの右端・左端を選択するとイベントの開始・終了時期を変更することができます。また、イベントを選択し、ドラッグすると、イベントを移動させることができます。"),
      tags$img(src = "event_move.png", title = "イベントの移動"),
      p("イベントの移動"),
      hr(),
      h5("イベントの削除"),
      HTML("<p>右側の赤色の<span style=\"color: red; font-weight: bold;\">×</span>をクリックすると、イベントが削除されます。</p>"),
      tags$img(src = "event_delete.png", title = "イベントの削除"),
      p("イベントの削除"),
      hr(),
      h3("タイムラインにアイテムを追加する"),
      p("タイムラインにアイテムを追加するときは、左の「アイテムを追加する」を用います。"),
      tags$img(src = "event_add_card.png", title = "イベントの追加"),
      p("イベントの追加"),
      h5("アイテムの情報"),
      p("アイテムには、項目名、開始日、終了日、タイプ、グループを指定します。指定後、「アイテム追加」のボタンを押すとアイテムを追加することができます。"),
      p(
        "開始日は終了日より早い時期を指定してください。
        項目名はイベントに表示されるテキストです。
        タイプはrange、box、pointから選択します。
        rangeは時間の幅のあるイベント、boxとpointは一時点を指定するイベントです。
        boxとpointでは、開始日と終了日が自動的に同日に設定されるようになっています。"),
      tags$img(src = "event_add_type.png", title = "イベントの種類"),
      p("イベントの種類"),
      hr(),
      h3("タイムラインのスクリーンショットを保存する"),
      p("タイムラインの下の「スクリーンショット」のボタンを押すと、スクリーンショットを保存することができます。
        スクリーンショットを取る際には、左の入力部分の一番上の<をクリックして、入力部分を隠すとよいでしょう。"),
      hr(),
      h3("グループの追加"),
      p("イベントをグループごとにまとめることができます。グループの追加には、左の「グループを追加する」を用います。
        グループの追加では、グループの色（タイムラインの左に示されるグループ名の部分）、アイテムの色を指定できます。
        色は「グループの色」の下に示されているものと同じになるので、確認しながら色を選択してください。"),
      tags$img(src = "add_group_card.png", title = "グループの追加"),
      p("グループの追加"),
      p("グループを追加すると、そのグループを「アイテムを追加する」で選択できるようになります。"),
      hr(),
      h3("グループの削除"),
      p("イベントを設定していないグループは削除することができます。グループの削除には、「グループを削除する」を用います。
        イベントをすでに設定しているグループは削除できず、グループをすべて削除することはできません。"),
      tags$img(src = "delete_group_card.png", title = "グループの削除"),
      p("グループの削除"),
      hr(),
      h3("イベント・グループの情報を表示する"),
      p("イベントやグループの情報の一覧は「詳細データ」のタブに表示されます。右上がイベントの情報、右下がグループの情報です。
        スタイルの情報はわかりにくいと思いますが、ChatGPTやGeminiに「background-color: #F4F9FF; color: #0D47A1;をHTMLで表示して」
        という形で質問すればイメージを表示してくれます。"),
      tags$img(src = "timeline_group_data.png", title = "イベント・グループの情報"),
      p("イベント・グループの情報"),
      hr(),
      h3("タイムラインのデータを保存する"),
      p("作成したタイムタイムラインは、「タイムラインデータを保存する」から保存できます。
        保存ファイルには自動的に名前がつけられますが、自由に変更しても問題ありません。
        保存ファイルは「タイムラインをアップロードする」から読み込むことができます。"),
      br(),
      p("＊Rに詳しい方向けの情報：保存ファイルはsaveRDSで保存した.Rdataファイルで、中身はリストです。
        リストの要素はイベントのデータフレーム、グループのデータフレーム、タイトルの3つです。
        RでreadRDS関数を用いて読み込み、データフレームを直接編集することでタイムラインを加工することもできます。"),
      hr(),
      h3("タイムラインデータの読み込み"),
      p("タイムラインの読み込みには、「タイムラインをアップロードする」を用います。「Browse...」の部分を
        クリックすると、ファイルを選択するウインドウが表示されますので、上記で保存したタイムラインのファイルを
        選択し、読み込んでください。なお、「アップロード」としていますが、ファイルがインターネット上に送られることは
        ありません。"),
      tags$img(src = "timeline_upload.png", title = "タイムラインのアップロード"),
      p("タイムラインのアップロード"),
      hr(),
      h3("Excelファイルの保存"),
      p("タイムラインをExcelのセルに反映したExcelファイルをダウンロードすることができます。
        ダウンロードには「詳細データ」タブの「Excelファイルを出力する」を用います。
        Excelファイルでのタイムラインは日・週・月の間隔でそれぞれ表示可能です。
        「出力の間隔」から選択して、「ダウンロード」をクリックするとExcelファイルが保存されます。"),
      br(),
      p("＊日数が700日（2年弱）、700週（13年）、700ヶ月（58年）を超えると表示がうまくいかなくなるので、長過ぎるスケジュールの場合はご注意ください。"),
      hr(),
      h3("参照情報"),
      p("このアプリケーションは以下のプログラム・ライブラリ等を利用して作成しました。"),
      a("R", href = "https://cran.r-project.org/"),
      br(),
      a("RStudio", href = "https://docs.posit.co/ide/user/"),
      br(),
      a("Shiny：Webアプリケーションフレームワーク", href = "https://shiny.posit.co"),
      br(),
      a("tidyverse：データの整理等", href = "https://tidyverse.org/"),
      br(),
      a("lubridate：日時データの加工", href = "https://lubridate.tidyverse.org/"),
      br(),
      a("bslib：Webアプリのテーマ・デザイン", href = "https://rstudio.github.io/bslib/"),
      br(),
      a("timevis：タイムラインの表示", href = "https://github.com/daattali/timevis"),
      br(),
      a("shinyscreenshot：スクリーンショットの保存", href = "https://github.com/daattali/shinyscreenshot"),
      br(),
      a("openxlsx2：Excelファイルの加工・出力", href = "https://janmarvin.github.io/openxlsx2/"),
      br(),
      a("shinylive：ローカル環境（Webブラウザ）上でのShinyの実行環境の構築", href = "https://posit-dev.github.io/r-shinylive/"),
      hr(),
      p("また、同等以上のJavascriptのアプリケーションを開発されている方もおられますので、こちらもチェックされると良いかと思います。"),
      a("Ganttline", href = "https://ganttline.csri16001.workers.dev/"),
      br(),
      a("Ganttline：Zennのページ", href = "https://zenn.dev/ricckyyy/articles/ganttline-introduction"),
      br()
    )
  )
)