library(shiny)
library(bslib)
library(timevis)
library(dplyr)
library(shinyscreenshot)
library(openxlsx2)
library(lubridate)
library(zip)

# システムの zip コマンドおよび bsdtar の使用を無効化し、zip パッケージを使わせる
options("openxlsx2.no_utils_zip" = TRUE)
options("openxlsx2.no_bsdtar" = TRUE)
options("openxlsx2.no_maybe_zip" = TRUE)

downloadButton <- function(...) {
  tag <- shiny::downloadButton(...)
  tag$attribs$download <- NULL
  tag
}

# フォントへのパスを指定
#sysfonts::font_paths("./")

# NotoSansJPをGoogle fontsからダウンロード
#sysfonts::font_add("noto", "NotoSansJP-VariableFont_wght.ttf") 

# showtextでのフォント設定を自動的に適用する
#showtext::showtext_auto()

# Excel出力時の時間間隔を指定するときに用いるベクター
timespan_translate <- c(month = "月", week = "週", day = "日")

# タイムライン・グループの色表現に関するベクター
TL_style <-
  c(
    blue   = "background-color: #E3F2FD; border-color: #1E88E5; color: #0D47A1;", # 1. Blue
    red    = "background-color: #FFEBEE; border-color: #E53935; color: #B71C1C;", # 2. Red
    green  = "background-color: #E8F5E9; border-color: #43A047; color: #1B5E20;", # 3. Green
    orange = "background-color: #FFF3E0; border-color: #FB8C00; color: #E65100;", # 4. Orange
    purple = "background-color: #F3E5F5; border-color: #8E24AA; color: #4A148C;", # 5. Purple
    teal   = "background-color: #E0F2F1; border-color: #00897B; color: #004D40;", # 6. Teal
    pink   = "background-color: #FCE4EC; border-color: #D81B60; color: #880E4F;", # 7. Pink
    blueGr = "background-color: #ECEFF1; border-color: #78909C; color: #263238;", # 8. Blue Grey
    yellow = "background-color: #FFFDE7; border-color: #FBC02D; color: #F57F17;", # 9. Yellow
    indigo = "background-color: #E8EAF6; border-color: #3F51B5; color: #1A237E;", # 10. Indigo
    deepOr = "background-color: #FBE9E7; border-color: #FF5722; color: #BF360C;", # 11. Deep Orange
    lime   = "background-color: #F0F4C3; border-color: #AFB42B; color: #827717;",  # 12. Lime
    amber  = "background-color: #FFF8E1; border-color: #FFA000; color: #FF6F00;", # 13. Amber
    cyan   = "background-color: #E0F7FA; border-color: #00ACC1; color: #006064;", # 14. Cyan
    deepPu = "background-color: #EDE7F6; border-color: #7E57C2; color: #311B92;"  # 15. Deep Purple
  )

group_style <- 
  c(
    blue   = "background-color: #F4F9FF; color: #0D47A1;", # 1. Blue
    red    = "background-color: #FFF5F5; color: #B71C1C;", # 2. Red
    green  = "background-color: #F4FBF5; color: #1B5E20;", # 3. Green
    orange = "background-color: #FFF9F1; color: #E65100;", # 4. Orange
    purple = "background-color: #FAF4FC; color: #4A148C;", # 5. Purple
    teal   = "background-color: #F2FBFB; color: #004D40;", # 6. Teal
    pink   = "background-color: #FFF5F8; color: #880E4F;", # 7. Pink
    blueGr = "background-color: #F7F9FA; color: #263238;", # 8. Blue Grey
    yellow = "background-color: #FFFFF2; color: #F57F17;", # 9. Yellow
    indigo = "background-color: #F5F6FC; color: #1A237E;", # 10. Indigo
    deepOr = "background-color: #FFF6F5; color: #BF360C;", # 11. Deep Orange
    lime   = "background-color: #FAFCF2; color: #827717;", # 12. Lime
    amber  = "background-color: #FFFDF5; color: #FF6F00;", # 13. Amber
    cyan   = "background-color: #F2FCFC; color: #006064;", # 14. Cyan
    deepPu = "background-color: #F7F5FC; color: #311B92;"  # 15. Deep Purple
  )

TL_color_names <- c(
  blue   = "ライトブルー",
  red    = "ライトレッド",
  green  = "ライトグリーン",
  orange = "オレンジ",
  purple = "パープル",
  teal   = "ティール",
  pink   = "ピンク",
  blueGr = "ブルーグレー",
  yellow = "イエロー",
  indigo = "インディゴ",
  deepOr = "ディープオレンジ",
  lime   = "ライム",
  amber  = "アンバー",
  cyan   = "シアン",
  deepPu = "ディープパープル"
)

# 起動時に表示されるグループ・タイムラインのデータを準備
default_group <- 
  tibble(
    id = 1,
    content = "グループ1",
    style = group_style[1]
  )

default_TL <-
  data.frame(
    id = 1,
    content = "イベント1",
    start = suppressWarnings(Sys.time() + days(1)),
    end = suppressWarnings(Sys.time() + days(30)),
    group = 1,
    type = "range",
    style = TL_style[1]
  )

# グループを追加するときの関数
add_group_f <- function(group_d, content, style){
  group_d |> 
    add_row(
      id = as.character(max(group_d$id |> as.numeric()) + 1) |> as.numeric(), 
      content = content, 
      style = group_style[style]
    )
}

# タイムラインのイベント追加のための関数
add_TLlist_f <- function(TL_d, content, start, end, group, type, style){
  TL_d |> 
    add_row(
      id = as.character(max(TL_d$id |> as.numeric()) + 1), 
      content = content, 
      start = start |> as.character(), 
      end = end |> as.character(),
      group = group,
      type = type,
      style = style)
}

# 日時の文字列表示を整える関数
prettyDate <- function(d) {
  pd <- \(d){
    posix <- as.POSIXct(d, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")
    corrected <- lubridate::with_tz(posix, "UTC")
    format(corrected, "%Y-%m-%d")}
  if (is.null(d)) return()
  ifelse(
    grepl("^\\d{4}-\\d{2}-\\d{2}$", d), # すでにYYYY-MM-DDである場合に対応できるようにする
    d,
    pd(d)
  )
}

# Excelでタイムラインを出力するための関数

# Excelでタイムラインを出力するための関数
output_excel_timeline <- function(d, timespan, mode, colorfills){
  # 列名のベクトルを作成
  colLetters <- 
    paste0(rep(c("", LETTERS), rep(26, 27)), LETTERS)
  
  # タイムラインのセルの色（backcolor2とグラデーションにできるようにする）
  backcolor =  rep(c(blue = "#90CAF9", red = "#EF9A9A", green = "#A5D6A7", orange = "#FFCC80", purple = "#CE93D8", teal = "#80CBC4", pink = "#F48FB1", blueGr = "#B0BEC5", yellow = "#FFF59D", indigo = "#9FA8DA", deepOr = "#FFAB91", lime = "#E6EE9C", amber = "#FFE082", cyan = "#80DEEA", deepPu = "#B39DDB"), 3)
  backcolor2 = rep(c(blue = "#B2EAFF", red = "#FAD2D2", green = "#D4EDDA", orange = "#FFE8CC", purple = "#EBE0F5", teal = "#D1F0EC", pink = "#FBD2E0", blueGr = "#E2E8F0", yellow = "#FFFDE0", indigo = "#DCE2F7", deepOr = "#FFDEC9", lime = "#F4F8D6", amber = "#FFF2CC", cyan = "#D1F5F8", deepPu = "#E4DCF5"), 3)
  
  # タイムラインのデータフレーム、グループのデータフレーム、タイトルを抽出（Shinyでは置き換えが必要）
  TL_d_forExcel <- d[[1]]
  group_d_forExcel <- d[[2]]
  title <- d[[3]]
  
  # 日時データ・グループを処理しやすいよう編集
  TL_d_forExcel$start <- prettyDate(TL_d_forExcel$start)
  TL_d_forExcel$end <- if_else(TL_d_forExcel$end |> is.na(), prettyDate(TL_d_forExcel$start), prettyDate(TL_d_forExcel$end))
  TL_d_forExcel$group <- as.integer(TL_d_forExcel$group)
  
  row_n <- nrow(TL_d_forExcel)
  
  # スケジュールの最も早い・遅い日時を取得  
  timerange <- c(TL_d_forExcel$start |> min(na.rm=TRUE), TL_d_forExcel$end |> max(na.rm=TRUE))
  
  # タイムラインをまとめたいときには埋める行を調整する
  if(mode == "まとめる"){
    TLgroups <- TL_d_forExcel$group |> unique() # グループを記録
    write_rows <- integer(nrow(TL_d_forExcel)) # 記録する行を書き込むためのベクター
    group_line <- NULL # グループ名を書く行を決めるためのベクター
    group_color <- integer(nrow(TL_d_forExcel)) # グループの色を決めるためのベクター
    for(i in 1:length(TLgroups)){
      temp_group_TL <- TL_d_forExcel |> filter(group == TLgroups[i]) # 同じグループのイベントを選択
      start_ <- temp_group_TL$start |> ymd() # Dateにしておく
      end_ <- temp_group_TL$end |> ymd()
      intr <- interval(start_, end_) # libridate::intevalで時間の範囲にする
      diftime <- outer(intr, intr, int_overlaps) # lubridate::int_overlapsをouterに適用し、2つずつの要素の重複を論理型の行列として返す
      diftime[upper.tri(diftime)] <- FALSE # 上三角行列を取得する
      diftime <- diftime |> apply(2, sum) |> dplyr::dense_rank() # 上三角行列の列方向にTRUEを数えると、スケジュールの重複が無いものを1つの行にまとめることができる
      wc_max <- ifelse(i == 1, 0, max(write_rows)) # write_rowsの最大値を取り、前のグループの次の行から書き込むようにする
      write_rows[TL_d_forExcel$group %in% i] <- diftime + wc_max # グループごとのイベントに書き込む行を設定する
      group_line <- c(group_line, rep(i, length(unique(diftime)))) # グループの書き込みするための列を指定
      if(colorfills == "グラデーション"){
        f <- colorRampPalette(c(backcolor[i], backcolor2[i]), length(unique(diftime))) # あらかじめグループ内の行数分だけグラデーションの色を作成する
        each_line_color <- f(length(diftime))
        group_color[TL_d_forExcel$group %in% i] <- each_line_color
      } else {
        group_color[TL_d_forExcel$group %in% i] <- backcolor[i]
      }
    }
    TL_d_forExcel$write_rows <- write_rows
    TL_d_forExcel$group_color <- group_color
  } else {
    TL_d_forExcel$write_rows <- 1:nrow(TL_d_forExcel)
    group_line <- TL_d_forExcel$group
    TL_d_forExcel$group_color <- backcolor[TL_d_forExcel$group]
  }
  
  # 書き込むセルの列を準備
  if(timespan == "月"){
    months_range <- interval(timerange[1], timerange[2]) |> time_length(unit="month") |> ceiling() + 2
    write_tl_range <- 3:(3 + months_range)
    
    timerange_year <- seq(timerange[1] |> ymd(), timerange[2] |> ymd() %m+% months(1), by = "month") |> year()
    timerange_year <- if_else(c(1, timerange_year[-length(timerange_year)]) == timerange_year, "", as.character(timerange_year))
    if(timerange[1] |> ymd() |> day() > 16){
      timerange_month <- seq(timerange[1] |> ymd() - days(15), timerange[2] |> ymd()  + days(15), by = "month") |> month()      
    } else {
      timerange_month <- seq(timerange[1] |> ymd(), timerange[2] |> ymd() %m+% months(1), by = "month") |> month()      
    }
    
    TL_d_forExcel <- 
      TL_d_forExcel |> 
      mutate(
        id = 1:row_n,
        group = as.integer(group),
        position_start = interval(timerange[1], start) |> time_length(unit="month") |> ceiling() + 3, # 開始位置の指定
        position_end = interval(timerange[1], end) |> time_length(unit="month") |> ceiling() + 3, # 終了位置の指定
        fillcells_value = paste0(colLetters[position_start], write_rows + 2), # ラベルを埋める部分のセルを指定
        fillcells = if_else(position_end - position_start == 0, fillcells_value, paste0(colLetters[position_start], write_rows +2, ":", colLetters[position_end], write_rows +2)) # 色を埋めるセル（スケジュールの期間）を指定
      )    
    
    timelinecells <- paste0(colLetters[(TL_d_forExcel$position_start |> min()) - 1], 1, ":", colLetters[(TL_d_forExcel$position_end |> max()) + 1], TL_d_forExcel$write_rows |> as.integer() |> max() + 2)
    
  }else if(timespan == "週"){
    weeks_range <- interval(timerange[1], timerange[2]) |> time_length(unit="week") |> ceiling() + 2
    write_tl_range <- 3:(3 + weeks_range)   
    
    timerange_year <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + weeks(1), by = "week") |> year() |> suppressWarnings()
    timerange_year <- if_else(c(1, timerange_year[-length(timerange_year)]) == timerange_year, "", as.character(timerange_year))
    timerange_month <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + weeks(1), by = "week") |> month() |> suppressWarnings()
    timerange_week <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + weeks(1), by = "week") |> week() |> suppressWarnings()
    
    TL_d_forExcel <- 
      TL_d_forExcel |> 
      mutate(
        id = 1:row_n,
        group = as.integer(group),
        position_start = interval(timerange[1], start) |> time_length(unit="week") |> ceiling() + 3, # 開始位置の指定
        position_end = interval(timerange[1], end) |> time_length(unit="week") |> ceiling() + 3, # 終了位置の指定
        fillcells_value = paste0(colLetters[position_start], write_rows + 3), # ラベルを埋める部分のセルを指定
        fillcells = if_else(position_end - position_start == 0, fillcells_value, paste0(colLetters[position_start], write_rows +3, ":", colLetters[position_end], write_rows +3)) # 色を埋めるセル（スケジュールの期間）を指定
      )
    
    timelinecells <- paste0(colLetters[(TL_d_forExcel$position_start |> min()) - 1], 1, ":", colLetters[(TL_d_forExcel$position_end |> max()) + 1], TL_d_forExcel$write_rows |> as.integer() |> max() + 3)
    
  }else if(timespan == "日"){
    days_range <- interval(timerange[1], timerange[2]) |> time_length(unit="day") |> ceiling() + 2
    write_tl_range <- 3:(3 + days_range)    
    
    timerange_year <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + days(1), by = "day") |> year() |> suppressWarnings()
    timerange_year <- if_else(c(1, timerange_year[-length(timerange_year)]) == timerange_year, "", as.character(timerange_year))
    timerange_month <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + days(1), by = "day") |> month() |> suppressWarnings()  
    timerange_week <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + days(1), by = "day") |> week() |> suppressWarnings() 
    timerange_day <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + days(1), by = "day") |> day() |> suppressWarnings() 
    
    TL_d_forExcel <- 
      TL_d_forExcel |> 
      mutate(
        id = 1:row_n,
        group = as.integer(group),
        position_start = interval(timerange[1], start) |> time_length(unit="day") |> ceiling() + 3, # 開始位置の指定
        position_end = interval(timerange[1], end) |> time_length(unit="day") |> ceiling() + 3, # 終了位置の指定
        fillcells_value = paste0(colLetters[position_start], write_rows + 4), # ラベルを埋める部分のセルを指定
        fillcells = if_else(position_end - position_start == 0, fillcells_value, paste0(colLetters[position_start], write_rows + 4, ":", colLetters[position_end], write_rows + 4)) # 色を埋めるセル（スケジュールの期間）を指定
      )
    
    timelinecells <- paste0(colLetters[(TL_d_forExcel$position_start |> min()) - 1], 1, ":", colLetters[(TL_d_forExcel$position_end |> max()) + 1], TL_d_forExcel$write_rows |> as.integer() |> max() + 4)
  }
  
  TL_d_forExcel <- TL_d_forExcel |> arrange(group, id)
  
  # openxlsx2でExcelファイルを編集する
  wb <- wb_workbook()
  wb$add_worksheet("タイムライン")
  wb$add_worksheet("タイムライン_データ")
  wb$add_worksheet("グループ_データ")
  
  wb$add_data("タイムライン_データ", TL_d_forExcel[, 1:7])$set_col_widths("タイムライン_データ", cols = 1:7, widths = "auto")
  wb$add_data("グループ_データ", group_d_forExcel)$set_col_widths("グループ_データ", cols = 1:3, widths = "auto")
  
  # セルの幅を調整
  wb$set_col_widths(sheet = "タイムライン", cols = write_tl_range, widths = 2.27)
  wb$set_col_widths(sheet = "タイムライン", cols = 1, widths = 12.42)
  wb$set_col_widths(sheet = "タイムライン", cols = 2, widths = 9.58)
  
  # 予定の列を利用してスケジュールを埋める
  for(i in 1:nrow(TL_d_forExcel)){
    wb$
      add_fill(sheet = "タイムライン", dims = TL_d_forExcel$fillcells[i], color = wb_color(TL_d_forExcel$group_color[i]))$
      add_data(sheet = "タイムライン", TL_d_forExcel$content[i], dims = TL_d_forExcel$fillcells_value[i])
  }
  
  
  # 年・月・週・月のデータ、罫線の追加
  wb$
    add_data(sheet = "タイムライン", timerange_year |> matrix(nrow = 1), col_names=FALSE, start_col = 3, start_row = 1)$
    add_data(sheet = "タイムライン", timerange_month |> matrix(nrow = 1), col_names = FALSE, start_col = 3, start_row = 2)$
    add_border(sheet = "タイムライン", timelinecells, inner_hgrid = "thin", inner_vgrid = "thin")$
    add_data(sheet = "タイムライン", "年", dims = paste0("B1"))$
    add_data(sheet = "タイムライン", "月", dims = paste0("B2"))
  
  if(timespan == "月"){
    wb$
      add_data(sheet = "タイムライン", group_d_forExcel$content[group_line], dims = paste0("B3"))$
      add_data(sheet = "タイムライン", title, dims = paste0("A3"))
  }
  
  if(timespan == "週"){
    wb$
      add_data(sheet = "タイムライン", timerange_week |> matrix(nrow = 1), col_names = FALSE, start_col = 3, start_row = 3)$
      add_data(sheet = "タイムライン", group_d_forExcel$content[group_line], dims = paste0("B4"))$
      add_data(sheet = "タイムライン", "週", dims = paste0("B3"))$
      add_data(sheet = "タイムライン", title, dims = paste0("A4"))
  }
  
  if(timespan == "日"){
    wb$
      add_data(sheet = "タイムライン", timerange_week |> matrix(nrow = 1), col_names = FALSE, start_col = 3, start_row = 3)$
      add_data(sheet = "タイムライン", timerange_day |> matrix(nrow = 1), col_names = FALSE, start_col = 3, start_row = 4)$
      add_data(sheet = "タイムライン", group_d_forExcel$content[group_line], dims = paste0("B5"))$
      add_data(sheet = "タイムライン", "週", dims = paste0("B3"))$
      add_data(sheet = "タイムライン", "日", dims = paste0("B4"))$
      add_data(sheet = "タイムライン", title, dims = paste0("A5"))
  }
  
  # Workbookオブジェクトを返す
  wb
}  