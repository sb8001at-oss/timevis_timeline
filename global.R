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
sysfonts::font_paths("./")

# NotoSansJPをGoogle fontsからダウンロード
sysfonts::font_add("noto", "NotoSansJP-VariableFont_wght.ttf") 

# showtextでのフォント設定を自動的に適用する
showtext::showtext_auto()

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
  if (is.null(d)) return()
  posix <- as.POSIXct(d, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")
  corrected <- lubridate::with_tz(posix, "UTC")
  format(corrected, "%Y-%m-%d")
}

# Excelでタイムラインを出力するための関数
output_excel_timeline <- function(d, timespan, title){
  # 列名のベクトルを作成
  colLetters <- 
    paste0(rep(c("", LETTERS), rep(26, 27)), LETTERS)
  
  # タイムラインのセルの色
  backcolor = c(blue = "#90CAF9", red = "#EF9A9A", green = "#A5D6A7", orange = "#FFCC80", purple = "#CE93D8", teal = "#80CBC4", pink = "#F48FB1", blueGr = "#B0BEC5", yellow = "#FFF59D", indigo = "#9FA8DA", deepOr = "#FFAB91", lime = "#E6EE9C", amber = "#FFE082", cyan = "#80DEEA", deepPu = "#B39DDB")
  
  # タイムラインのデータフレーム、グループのデータフレーム、タイトルを抽出（Shinyでは置き換えが必要）
  TL_d_forExcel <- d[[1]]
  group_d_forExcel <- d[[2]]
  title <- d[[3]]
  
  # 日時データ・グループを処理しやすいよう編集
  TL_d_forExcel$start <- prettyDate(TL_d_forExcel$start)
  TL_d_forExcel$end <- prettyDate(TL_d_forExcel$end)
  TL_d_forExcel$group <- as.integer(TL_d_forExcel$group)
  
  # スケジュールの最も早い・遅い日時を取得  
  timerange <- c(TL_d_forExcel$start |> min(na.rm=TRUE), TL_d_forExcel$end |> max(na.rm=TRUE))

  # 書き込むセルの列を準備
  if(timespan == "月"){
    months_range <- interval(timerange[1], timerange[2]) |> time_length(unit="month") |> ceiling() + 2
    write_tl_range <- 3:(3 + months_range)
  }else if(timespan == "週"){
    weeks_range <- interval(timerange[1], timerange[2]) |> time_length(unit="week") |> ceiling() + 2
    write_tl_range <- 3:(3 + weeks_range)   
  }else if(timespan == "日"){
    days_range <- interval(timerange[1], timerange[2]) |> time_length(unit="day") |> ceiling() + 2
    write_tl_range <- 3:(3 + days_range)    
  }
  
  # 年・月のベクターを生成
  if(timespan == "月"){
    timerange_year <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + months(1), by = "month") |> year()
    timerange_year <- if_else(c(1, timerange_year[-length(timerange_year)]) == timerange_year, "", as.character(timerange_year))
    if(timerange[1] |> ymd() |> day() > 16){
      timerange_month <- seq(timerange[1] |> ymd() - days(15), timerange[2] |> ymd()  + days(15), by = "month") |> month()      
    } else {
      timerange_month <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + months(1), by = "month") |> month()      
    }

  } else if(timespan == "週"){
    timerange_year <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + weeks(1), by = "week") |> year() |> suppressWarnings()
    timerange_year <- if_else(c(1, timerange_year[-length(timerange_year)]) == timerange_year, "", as.character(timerange_year))
    timerange_month <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + weeks(1), by = "week") |> month() |> suppressWarnings()
    timerange_week <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + weeks(1), by = "week") |> week() |> suppressWarnings()
  } else if(timespan == "日"){
    timerange_year <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + days(1), by = "day") |> year() |> suppressWarnings()
    timerange_year <- if_else(c(1, timerange_year[-length(timerange_year)]) == timerange_year, "", as.character(timerange_year))
    timerange_month <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + days(1), by = "day") |> month() |> suppressWarnings()  
    timerange_week <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + days(1), by = "day") |> week() |> suppressWarnings() 
    timerange_day <- seq(timerange[1] |> ymd(), timerange[2] |> ymd()  + days(1), by = "day") |> day() |> suppressWarnings()   
  }
  
  # タイムラインのデータフレームを整理し、埋めるセルを評価しやすくする
  if(timespan == "月"){
    TL_d_forExcel <- 
      TL_d_forExcel |> 
      mutate(
        id = as.integer(id),
        group = as.integer(group),
        position_start = interval(timerange[1], start) |> time_length(unit="month") |> floor() + 3, # 開始位置の指定
        position_end = interval(timerange[1], end) |> time_length(unit="month") |> floor() + 3, # 終了位置の指定
        fillcells_value = paste0(colLetters[position_start], id + 2), # ラベルを埋める部分のセルを指定
        fillcells = if_else(position_end - position_start == 0, fillcells_value, paste0(colLetters[position_start], id +2, ":", colLetters[position_end], id +2)) # 色を埋めるセル（スケジュールの期間）を指定
      )
  }else if(timespan == "週"){
    TL_d_forExcel <- 
      TL_d_forExcel |> 
      mutate(
        id = as.integer(id),
        group = as.integer(group),
        position_start = interval(timerange[1], start) |> time_length(unit="week") |> floor() + 3, # 開始位置の指定
        position_end = interval(timerange[1], end) |> time_length(unit="week") |> floor() + 3, # 終了位置の指定
        fillcells_value = paste0(colLetters[position_start], id + 3), # ラベルを埋める部分のセルを指定
        fillcells = if_else(position_end - position_start == 0, fillcells_value, paste0(colLetters[position_start], id +3, ":", colLetters[position_end], id +3)) # 色を埋めるセル（スケジュールの期間）を指定
      )
  }else if(timespan == "日"){
    TL_d_forExcel <- 
      TL_d_forExcel |> 
      mutate(
        id = as.integer(id),
        group = as.integer(group),
        position_start = interval(timerange[1], start) |> time_length(unit="day") |> floor() + 3, # 開始位置の指定
        position_end = interval(timerange[1], end) |> time_length(unit="day") |> floor() + 3, # 終了位置の指定
        fillcells_value = paste0(colLetters[position_start], id + 4), # ラベルを埋める部分のセルを指定
        fillcells = if_else(position_end - position_start == 0, fillcells_value, paste0(colLetters[position_start], id +4, ":", colLetters[position_end], id +4)) # 色を埋めるセル（スケジュールの期間）を指定
      )
  }
  
  # 1日しか差がないときの取り扱いを指定
  TL_d_forExcel <- 
    TL_d_forExcel |> 
    mutate(position_end = if_else(position_end - position_start == 1, position_start, position_end))

  # タイムラインを埋めるセルの範囲を指定
  if(timespan == "月"){
    timelinecells <- paste0(colLetters[(TL_d_forExcel$position_start |> min()) - 1], 1, ":", colLetters[(TL_d_forExcel$position_end |> max()) + 1], TL_d_forExcel$id |> as.integer() |> max() + 2) 
  }else if(timespan == "週"){
    timelinecells <- paste0(colLetters[(TL_d_forExcel$position_start |> min()) - 1], 1, ":", colLetters[(TL_d_forExcel$position_end |> max()) + 1], TL_d_forExcel$id |> as.integer() |> max() + 3)
  }else if(timespan == "日"){
    timelinecells <- paste0(colLetters[(TL_d_forExcel$position_start |> min()) - 1], 1, ":", colLetters[(TL_d_forExcel$position_end |> max()) + 1], TL_d_forExcel$id |> as.integer() |> max() + 4)
  }
  
  # openxlsx2でExcelファイルを編集する
  wb <-wb_workbook()
  wb$add_worksheet("タイムライン")
  wb$add_worksheet("タイムライン_データ")
  wb$add_worksheet("グループ_データ")
  
  wb$add_data("タイムライン_データ", TL_d_forExcel)$set_col_widths("タイムライン_データ", cols = 1:11, widths = "auto")
  wb$add_data("グループ_データ", group_d_forExcel)$set_col_widths("グループ_データ", cols = 1:3, widths = "auto")
  
  # セルの幅を調整
  wb$set_col_widths(sheet = "タイムライン", cols = write_tl_range, widths = 2.27)
  wb$set_col_widths(sheet = "タイムライン", cols = 1, widths = 12.42)
  wb$set_col_widths(sheet = "タイムライン", cols = 2, widths = 9.58)
  
  # 予定の列を利用してスケジュールを埋める
  for(i in 1:nrow(TL_d_forExcel)){
    wb$
      add_fill(sheet = "タイムライン", dims = TL_d_forExcel$fillcells[i], color = wb_color(hex = backcolor[TL_d_forExcel$group[i]]))$
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
      add_data(sheet = "タイムライン", group_d_forExcel$content[TL_d_forExcel$group[1:nrow(TL_d_forExcel)]], dims = paste0("B3"))$
      add_data(sheet = "タイムライン", title, dims = paste0("A3"))
  }
  
  if(timespan == "週"){
    wb$
      add_data(sheet = "タイムライン", timerange_week |> matrix(nrow = 1), col_names = FALSE, start_col = 3, start_row = 3)$
      add_data(sheet = "タイムライン", group_d_forExcel$content[TL_d_forExcel$group[1:nrow(TL_d_forExcel)]], dims = paste0("B4"))$
      add_data(sheet = "タイムライン", "週", dims = paste0("B3"))$
      add_data(sheet = "タイムライン", title, dims = paste0("A4"))
  }
  
  if(timespan == "日"){
    wb$
      add_data(sheet = "タイムライン", timerange_week |> matrix(nrow = 1), col_names = FALSE, start_col = 3, start_row = 3)$
      add_data(sheet = "タイムライン", timerange_day |> matrix(nrow = 1), col_names = FALSE, start_col = 3, start_row = 4)$
      add_data(sheet = "タイムライン", group_d_forExcel$content[TL_d_forExcel$group[1:nrow(TL_d_forExcel)]], dims = paste0("B5"))$
      add_data(sheet = "タイムライン", "週", dims = paste0("B3"))$
      add_data(sheet = "タイムライン", "日", dims = paste0("B4"))$
      add_data(sheet = "タイムライン", title, dims = paste0("A5"))
  }
  
  # Workbookオブジェクトを返す
  wb
}  