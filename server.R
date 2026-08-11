function(input, output, session) {
  
  # タイムラインのタイトル（表題）を反映させる
  output$title_out <- renderText(input$title_in)
  
  # reactiveValでイベント・グループのデータフレームを管理・初期化
  timeline_d <- reactiveVal(default_TL)
  group_d <- reactiveVal(default_group)
  
  # グループの追加
  observeEvent(
    input$add_group, 
    {
      # 同じグループ名を設定するとtimevisでエラーになる
      if(sum(group_d()$content %in% input$name_new_group) != 0){
        showNotification("同じグループ名は設定できません", duration = 5, type = "error")
        return(0)
      }
      
      group_d(
        group_d() |> 
          add_group_f(
            content = input$name_new_group,
            style = input$style_new_group
          )
      )
    })
  
  # Rdataファイルの読み込み
  observeEvent(
    input$TL_file,
    {
      req(input$TL_file)
      TLobj <- readRDS(input$TL_file$datapath)
      timeline_d(TLobj[[1]])
      group_d(TLobj[[2]])
      updateTextInput(session, "title_in", value = TLobj[[3]])
    }
  )
  
  # グループを削除
  observeEvent(
    input$delete_group,
    {
      # groupのidを取得し，イベントを含むグループを削除する場合にはエラーメッセージを表示する
      group_delete_id <- group_d()$id[group_d()$content %in% input$group_item3]
      if(sum(timeline_d()$group %in% group_delete_id) > 0){
        showNotification("イベントが設定されているグループは削除できません", duration = 5, type = "error")
        return(0)
      }
      if(nrow(group_d()) == 1){
        showNotification("グループが1つしかないので，削除できません", duration = 5, type = "error")
        return(0)
      }
      
      # group idを用いてグループを削除する
      group_d(
        group_d() |> filter(id != group_delete_id)
      )
    }
  )
  
  # イベントの追加
  observeEvent(
    input$add_TL,
    {
      # 終了日が開始日より前の場合にはエラーメッセージを表示し，イベントを追加しない
      if(ymd(input$date_end) < ymd(input$date_start)){
        showNotification("終了日は開始日より後に設定してください", duration = 5, type = "error")
        return(0)
      }
      
      # イベントの色はグループから設定するようにしている
      style_TL_index <- which(group_style == group_d() |> filter(content == input$group_item) |> _$style)
      
      # box，pointを選択した場合には終了日と開始日を同日とする
      temp_end <-
        if_else(input$type_item == "range", input$date_end, input$date_start)
      
      # timeline用のデータフレームの行が0の時と，それ以外は別で処理する（0の時はデータフレームを新規作成）
      if(input$vistimeline_data |> length() > 0){
        current_TL_d <- input$vistimeline_data
        current_TL_d <-
          current_TL_d |> 
          add_TLlist_f(
            content = input$name_item,
            start = input$date_start,
            end = temp_end,
            group = group_d() |> filter(content == input$group_item) |> _$id |> as.character(),
            type = input$type_item,
            style = TL_style[style_TL_index]
          )
      } else {
        # これを入れないとtimeline_dが（reactiveだから）変更されず、observerが機能しない場合がある
        timeline_d(input$vistimeline_data) 
        current_TL_d <- 
          data.frame(
          id = 1,
          content = input$name_item,
          start = input$date_start,
          end = temp_end,
          group = group_d() |> filter(content == input$group_item) |> _$id |> as.character(),
          type = input$type_item,
          style = TL_style[style_TL_index]
         )
      }
      timeline_d(current_TL_d)
    }
  )

  
  # イベントの編集
  observeEvent(
    input$update_TL,
    {
      # 終了日が開始日より前の場合にはエラーメッセージを表示し，イベントを追加しない
      if(ymd(input$date_end_update) < ymd(input$date_start_update)){
        showNotification("終了日は開始日より後に設定してください", duration = 5, type = "error")
        return(0)
      }
      
      # イベントの色はグループから設定するようにしている
      style_TL_index <- which(group_style == group_d() |> filter(content == input$group_item2) |> _$style)
      
      # box，pointを選択した場合には終了日と開始日を同日とする
      temp_end <-
        if_else(input$type_item_update == "range", input$date_end_update, input$date_start_update)
      
      # timeline用のデータフレームをアップデート
        current_TL_d <- input$vistimeline_data
        current_TL_d <-
          current_TL_d |> 
          mutate(eventtag = paste(id, ", ", content)) |> 
          filter(eventtag != input$TLcontent) |> 
          select(-eventtag) |> 
          add_TLlist_f(
            content = input$name_item_update,
            start = input$date_start_update,
            end = temp_end,
            group = group_d() |> filter(content == input$group_item2) |> _$id |> as.character(),
            type = input$type_item_update,
            style = TL_style[style_TL_index]
          )
      timeline_d(current_TL_d)
    }
  )
    
  # グループの色指定をわかりやすくするためのテキストを準備
  output$css_group_image <- 
    renderText({
      HTML(paste0("<p style=\"", group_style[input$style_new_group], "\"> グループの色 </p>"))
    })
  
  output$css_TL_image <- 
    renderText({
      HTML(paste0("<p style=\"", TL_style[input$style_new_group], "\"> TLの色 </p>"))
    })
  
  # timevisでタイムラインを表示
  output$vistimeline <-
    renderTimevis(
      timevis(
        data = timeline_d(), 
        groups = group_d(), 
        showZoom = FALSE,
        options = 
          list(
            min = ymd(timeline_d()$start) |> min() |> suppressWarnings() - days(30), 
            max = ymd(timeline_d()$end) |> max() |> suppressWarnings() + days(30), 
            editable = TRUE, 
            multiselect = TRUE,
            showCurrentTime = FALSE
          )
      )
    )
  
  # グループを追加したら，グループ名のselectInputをアップデートする
  output$group_names_input <-
    renderUI(
      selectInput(
        "group_item", 
        "グループ", 
        choices = group_d()$content
      )
    )
  
  # グループを追加したら，グループ名のselectInputをアップデートする2（名前の問題を解決するためのもの）
  output$group_names_input2 <-
    renderUI(
      selectInput(
        "group_item2", 
        "グループ", 
        choices = group_d()$content
      )
    )  

  # グループを追加したら，グループ名のselectInputをアップデートする3（名前の問題を解決するためのもの）
  output$group_names_input3 <-
    renderUI(
      selectInput(
        "group_item3", 
        "グループ", 
        choices = group_d()$content
      )
    )  
  
  
  # イベント変更のためのUIを準備する
  output$event_names_input <-
    renderUI(
      selectInput(
        "TLcontent", 
        "イベント名", 
        choices = paste(input$vistimeline_data$id, ", ", input$vistimeline_data$content),
      )
    )  
  
  # イベント・グループのデータを表示する
  output$TL_table <- renderTable({
    input$vistimeline_data |> 
      mutate(
        start = prettyDate(start),
        end = prettyDate(end),
        style = TL_color_names[which(TL_style == style) |> names()]
        ) |> 
      rename(`項目` = content, `開始` = start, `完了` = end, `グループ` = group, , `タイプ` = type, `スタイル` = style) 
  })
  
  output$group_table <- renderTable({
    group_d() |> 
      mutate(
        id = as.integer(id),
        style = TL_color_names[which(group_style == style) |> names()]
      ) |> 
      rename(`グループ名` = content, `スタイル` = style) 
  })
  
  # スクリーンショット撮影
  observeEvent(input$go, {
    screenshot()
  })
  
  # ダウンロードするRdataファイルの準備
  output$downloadData <- downloadHandler(
    filename = function(){
      paste0("Timeline_", input$title_in, "_", Sys.Date(), ".Rdata")
    },
    content = function(file){
      outfile <- list(input$vistimeline_data, group_d(), input$title_in)
      saveRDS(outfile, file)
    }
  )
  
  # ダウンロードするExcelファイルの準備
  output$downloadExcel <- downloadHandler(
    filename = function(){
      paste0(
        "timeline_", input$name_product, Sys.Date(), timespan_translate[timespan_translate %in% input$timespan_selected] |> names(), ".xlsx")
    },
    content = function(file){
      # validate(need(FALSE, NULL))で実行されないはずだが，うまく機能しない
      if(input$timespan_selected == "日" & length(seq(input$vistimeline_data$start |> prettyDate() |> ymd() |> min(na.rm=TRUE), input$vistimeline_data$end |> prettyDate() |> ymd() |> max(na.rm=TRUE), by = "day")) > 700){
        showNotification("スケジュールが長過ぎるので「日」は選択できません。「週」か「月」を選んでください。", duration = 5, type = "error")
        validate(need(FALSE, NULL)) 
      }
      
      output_excel_timeline(list(input$vistimeline_data, group_d(), input$title_in), input$timespan_selected, input$mode_output, input$color_output)$save(file)
    }
  )
}