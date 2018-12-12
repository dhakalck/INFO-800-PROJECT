library(shiny)
load('RandomF.rda')


ui <- fluidPage(
  headerPanel("Weekly Food Expenditure"), 
  sidebarPanel(
    
    selectInput("hhsize", 'Household Size', choices = c('1', '2', '3', '4' , '5')), 
    sliderInput('itemstot', ' No of Item Purchased', min = 1, max = 50, value = 20),
    sliderInput('inchhavg_r', 'Monthly Income', min = 100, max = 10000, value = 1000),
    selectInput('grocerylistfreq', 'Frequency of shopping', choices = c('1', '2', '3', '4' , '5')),
    sliderInput('primstoredist_d', 'Distance to Primary Grocery Store', min = 0.5, max = 10, value = 5),
    
    
    actionButton('pred_but', 'Model')),
  mainPanel(
    h3('Food Spending (Y?N)'),
    p('Do you spend enough $ amount on food? '), 
    textOutput('prediction')
  )
)  




server <- function(input, output){
  vicdata <- eventReactive(input$pred_but, {
    inputhhsize <- input$hhsize
    inputitemstot <- input$itemstot
    inputinchhavg_r <- input$inchhavg_r
    inputgrocerylistfreq <- input$grocerylistfreq 
    inputprimstoredist_d <- input$primstoredist_d 
    
    
    new_pre <- predict(model_rf, data.frame(hhsize = inputhhsize, itemstot= inputitemstot,
                                          inchhavg_r = inputinchhavg_r, grocerylistfreq = inputgrocerylistfreq, primstoredist_d = inputprimstoredist_d 
))
  } )
  output$prediction <-renderText(vicdata())
  output$plot1 <- renderPlot({
    plot(mtcars$wt, mtcars$mpg)
  })
}
shinyApp(ui, server)