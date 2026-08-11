ui <- page_sidebar(
  theme = bs_theme(bootswatch = "united"),
  title = "タイムライン作成",
  sidebar = sidebar(  
    accordion(
      open = FALSE,
      multiple = FALSE,
      accordion_panel(
        "タイムラインを読み込む",
        fileInput("TL_file", NULL, accept=".Rdata")
      ),
      
      accordion_panel(
        "タイムラインのタイトル",
        textInput("title_in", NULL, value = "タイトル")
      ),
    
      accordion_panel(
        "イベントを追加する",
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
        actionButton("add_TL", "イベント追加")
      ),
  
      accordion_panel(
        "イベントを編集する",
        uiOutput("event_names_input"),
        textInput("name_item_update", "項目名", value = "XXX"),
        dateInput("date_start_update", "開始日", value = Sys.Date()), 
        dateInput("date_end_update", "終了日", value = Sys.Date()+months(1)),
        selectInput(
          "type_item_update",
          "タイプ",
          choices = c("box", "range", "point"),
          selected = "range"
        ),
        uiOutput("group_names_input2"),
        actionButton("update_TL", "イベント編集")
      ),
      
      accordion_panel(
        "グループを追加する",
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
      ),
      
      accordion_panel(
        "グループを削除する",
        uiOutput("group_names_input3"),
        actionButton("delete_group", "グループ削除")
      ),
      
      accordion_panel(
        "タイムラインデータを保存する",
        downloadButton("downloadData", "ダウンロード")
      ),
      
      accordion_panel(
        "Excelファイルを出力する",
        selectInput("timespan_selected", "出力の間隔", choices = c("月", "週", "日"), selected = "月"),
        selectInput(
          "mode_output",
          "イベントの表記",
          choices = c("まとめる", "一行ずつ表記"),
          selected = "まとめる"
        ),
        selectInput(
          "color_output",
          "イベントの色",
          choices = c("グラデーション", "単色"),
          selected = "グラデーション"
        ),
        downloadButton("downloadExcel", "ダウンロード")
      )
    ),
    
    tags$a(href = "https://github.com/sb8001at-oss/timevis_timeline", icon("github"), "ソースコード", target = "_blank"),
    p("© xjorv, 2026"),
    tags$a(href = "https://creativecommons.org/licenses/by-nc-sa/4.0/deed.ja", img(src = "by-nc-sa.png", style = "width: 100px; height: auto;"), target = "_blank"),
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
      card(card_header("タイムラインの情報"), card_body(tableOutput("TL_table"))),
      card(card_header("グループの情報"), card_body(tableOutput("group_table")))
    ),
    
    nav_panel(
      title = "使い方",
      accordion(
        multiple = FALSE,
        accordion_panel(
          "このアプリについて",
          p(
            "このアプリはShinyというWebアプリケーション作成ソフトウェアを用いて作成しました。
            このWebアプリはあなたのPCのブラウザの演算能力を用いて動いています。
            ですので、Webを通じてファイルをインターネットにアップロードすることはありません。"
          )
        ),
        
        accordion_panel(
          "タイムラインにタイトルをつける",
          p("タイムラインのタイトルは、左に表示されている「タイムラインのタイトル」の部分に入力します。"),
          tags$img(src = "card_title.png", title = "タイムラインのタイトル"),
          p("タイムラインのタイトル")
        ),
        
        accordion_panel(
          "タイムラインの操作",
          accordion(
            open = FALSE,
            multiple = FALSE,
            accordion_panel(
              "タイムラインの表示例",
              p("タイムラインには、左上にタイトル、グループとイベント、下に年月日が表示されます。さらにその下にはスクリーンショットを取るためのボタンがあります。"),
              tags$img(src = "timeline_example.png", title = "タイムラインの表示例"),
              p("タイムラインの表示例")
            ),
            accordion_panel(
              "タイムラインの拡大・縮小",
              p("このタイムライン上でマウスのホイールを回転させるとタイムラインを拡大・縮小することができます。"),
              tags$img(src = "timeline_zoomout.png", title = "タイムラインの拡大・縮小"),
              p("タイムラインの拡大・縮小")
            ),
            accordion_panel(
              "タイムラインの移動",
              p("タイムライン上でドラッグすると、タイムラインの位置を移動させることができます。"),
              tags$img(src = "timeline_move.png", title = "タイムラインの移動"),
              p("タイムラインの移動")
            ),
            accordion_panel(
              "イベントの選択",
              HTML("<p>タイムライン上のイベントは選択することができます。選択すると、右側に赤色の<span style=\"color: red; font-weight: bold;\">×</span>が表示されます。</p>×を押すと、イベントが削除されます。"),
              tags$img(src = "timeline_select.png", title = "イベントの選択"),
              p("イベントの選択")
            ),
            accordion_panel(
              "複数イベントの選択",
              p("Ctrlを押しながらイベントを選択すると、複数のイベントを選択することができます。"),
              tags$img(src = "timeline_multiselect.png", title = "複数イベントの選択"),
              p("複数イベントの選択")
            ),
            accordion_panel(
              "イベントの移動",
              p("イベントの右端・左端を選択するとイベントの開始・終了時期を変更することができます。また、イベントを選択し、ドラッグすると、イベントを移動させることができます。"),
              tags$img(src = "event_move.png", title = "イベントの移動"),
              p("イベントの移動")
            ),
            accordion_panel(
              "イベントの削除",
              HTML("<p>右側の赤色の<span style=\"color: red; font-weight: bold;\">×</span>をクリックすると、イベントが削除されます。</p>"),
              tags$img(src = "event_delete.png", title = "イベントの削除"),
              p("イベントの削除")
            )
          )
        ),
        
        accordion_panel(
          "タイムラインにアイテムを追加する",
          p("タイムラインにアイテムを追加するときは、左の「イベントを追加する」を用います。"),
          tags$img(src = "event_add_card.png", title = "イベントの追加"),
          p("イベントの追加"),
          hr(),
          h5("イベントの情報"),
          p("イベントには、項目名、開始日、終了日、タイプ、グループを指定します。指定後、「イベント追加」のボタンを押すとイベントを追加することができます。"),
          p(
            "開始日は終了日より早い時期を指定してください。
          項目名はイベントに表示されるテキストです。
          タイプはrange、box、pointの3つから選択します。
          rangeは時間の幅のあるイベント、boxとpointは一時点を指定するイベントです。
          boxとpointでは、開始日と終了日が自動的に同日に設定されるようになっています。"),
          tags$img(src = "event_add_type.png", title = "イベントの種類"),
          p("イベントの種類")
        ),
        
        accordion_panel(
          "タイムラインのスクリーンショットを保存する",
          p("タイムラインの下の「スクリーンショット」のボタンを押すと、スクリーンショットを保存することができます。
          スクリーンショットを取る際には、左の入力部分の一番上の<をクリックして、入力部分を隠すとよいでしょう。")
        ),
        
        accordion_panel(
          "グループの追加",
          p("イベントをグループごとにまとめることができます。グループの追加には、左の「グループを追加する」を用います。
            グループの追加では、グループの色（タイムラインの左に示されるグループ名の部分）、イベントの色を指定できます。
            色は「グループの色」の下に示されているものと同じになるので、確認しながら色を選択してください。"),
          tags$img(src = "add_group_card.png", title = "グループの追加"),
          p("グループの追加"),
          p("グループを追加すると、そのグループを「イベントを追加する」で選択できるようになります。")
        ),

        accordion_panel(
          "グループの削除",
          p("イベントを設定していないグループは削除することができます。グループの削除には、「グループを削除する」を用います。
          イベントをすでに設定しているグループは削除できず、グループをすべて削除することはできません。"),
          tags$img(src = "delete_group_card.png", title = "グループの削除"),
          p("グループの削除")
        ),
        
        accordion_panel(        
          "イベント・グループの情報を表示する",
          p("イベントやグループの情報の一覧は「詳細データ」のタブに表示されます。右上がイベントの情報、右下がグループの情報です。"),
          tags$img(src = "timeline_group_data.png", title = "イベント・グループの情報"),
          p("イベント・グループの情報"),
        ),
        
        accordion_panel(         
          "タイムラインのデータを保存する",
          p("作成したタイムタイムラインは、「タイムラインデータを保存する」から保存できます。
          保存ファイルには自動的に名前がつけられますが、自由に変更しても問題ありません。
          保存ファイルは「タイムラインをアップロードする」から読み込むことができます。"),
          tags$img(src = "save_timeline.png", title = "タイムラインのデータを保存する"),
          p("タイムラインのデータを保存する"),
          br(),
          p("＊Rに詳しい方向けの情報：保存ファイルはsaveRDSで保存した.Rdataファイルで、中身はリストです。
          リストの要素はイベントのデータフレーム、グループのデータフレーム、タイトルの3つです。
          RでreadRDS関数を用いて読み込み、データフレームを直接編集することでタイムラインを加工することもできます。"),
        ),

        accordion_panel(         
          "タイムラインデータの読み込み",
          p("タイムラインの読み込みには、「タイムラインを読み込む」を用います。「Browse...」の部分を
          クリックすると、ファイルを選択するウインドウが表示されますので、上記で保存したタイムラインのファイルを
          選択し、読み込んでください。なお、読み込んだファイルがインターネット上に送られることは
          ありません。"),
          tags$img(src = "timeline_upload.png", title = "タイムラインの読み込み"),
          p("タイムラインの読み込み"),
        ),
        
        accordion_panel(         
          "Excelファイルの出力",
          p("タイムラインをExcelのセルに反映したExcelファイルをダウンロードすることができます。
          ダウンロードには「詳細データ」タブの「Excelファイルを出力する」を用います。
          Excelファイルでのタイムラインは日・週・月の間隔でそれぞれ表示可能です。
          「出力の間隔」から選択して、「ダウンロード」をクリックするとExcelファイルが保存されます。"),
          p("また、イベントの表記をグループごとにまとめる、各イベントをそれぞれ一行に表示するかどうかを選択することもできます。"),
          p("イベントの色はグループごとに決められますが、イベント間で色をグラデーションとして少しずつ変えることもできます。"),
          br(),
          p("＊日数が338日（1年弱）、338週（6.5年）、338ヶ月（28年）を超えると表示がうまくいかなくなるので、スケジュールが長過ぎる場合にはご注意ください。"),
        ),
        
        accordion_panel(            
          "参照情報",
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
        )
      )

    )
  )
)