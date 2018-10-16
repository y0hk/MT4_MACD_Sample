//+------------------------------------------------------------------+
//|                                                      ea_test.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
// 注意事項
// ＃本ツールは、ツール内でポジショニングしたものしか処理を行いません。
// ＃事前のポジションはすべて清算してポジションが無い状態で実行してください。

#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define NONE_POSITION 0x00 // ポジションなし
#define BUY_POSITION 0x01  // BUY
#define SELL_POSITION 0x10 // SELL

#define DEFAULT_LOTS 0.1
#define DEFAULT_SLIPPAGE 0

#define MAIL_SUBJECT "EA_TEST_ARART"
#define MAIL_UPTEXT "価格が上がりました。"
#define MAIL_DOWNTEXT "価格が下がりました。"

// Input parameters
input double Lots = DEFAULT_LOTS;      // 注文ロット数
input int Slippage = DEFAULT_SLIPPAGE; // 許容スリッページ（ポイント）
input bool SendML = false;             // 転換時のメール送信

 
// Global parameters
int Ticket = -1;                  //　チケット番号
char Position = NONE_POSITION;   // ポジションフラグ
string Indicator_Name = "MACD_test";


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   bool ret;
   // Get MACD data
   double macd0 = iCustom(_Symbol, 0, Indicator_Name, 0, 0);
   double macd1 = iCustom(_Symbol, 0, Indicator_Name, 0, 1);
   
   // Get ReferMacdUpdata
   double refermacdup0 = iCustom(_Symbol, 0, Indicator_Name, 6, 0);
      
   if(macd0 > macd1){
      // Buy position
      if(Position & BUY_POSITION){ return; }
      if(Position & SELL_POSITION){
         OrderSelect(Ticket, SELECT_BY_TICKET);
         ret = OrderClose(Ticket, OrderLots(), OrderClosePrice(), Slippage);
         if(ret){ Ticket = -1; Position = NONE_POSITION; }
      }
      
      if(refermacdup0 != EMPTY_VALUE){
//         if(SendML){ SendMail( MAIL_SUBJECT, MAIL_UPTEXT ); }
         Ticket = OrderSend(_Symbol, OP_BUY, Lots, Ask, Slippage, 0, 0);
         if(Ticket != -1){ Position = BUY_POSITION; }
      }
   }else if(macd0 < macd1){
      // Sell position
      if(Position & SELL_POSITION){ return; }
      if(Position & BUY_POSITION){
         OrderSelect(Ticket, SELECT_BY_TICKET);
         ret = OrderClose(Ticket, OrderLots(), OrderClosePrice(), Slippage);
         if(ret){ Ticket = -1; Position = NONE_POSITION; }         
      }
      
      if(refermacdup0 == EMPTY_VALUE){
//         if(SendML){ SendMail( MAIL_SUBJECT, MAIL_DOWNTEXT ); }         
         Ticket = OrderSend(_Symbol, OP_SELL, Lots, Bid, Slippage, 0, 0);      
         if(Ticket != -1){ Position = SELL_POSITION; }
      }
   }
   return;
  }
  
  
//+------------------------------------------------------------------+
