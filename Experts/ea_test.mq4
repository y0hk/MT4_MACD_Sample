//+------------------------------------------------------------------+
//|                                                      ea_test.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// Position bit
#define NONE_POSITION 0x00 // Non Position
#define BUY_POSITION 0x01  // BUY
#define SELL_POSITION 0x02 // SELL

#define DEFAULT_LOTS 0.1
#define DEFAULT_SLIPPAGE 0

#define ENTRY  1
#define CLOSE  2

// Message Strings
#define PERIOD_ERROR_MESSAGE "週軸及び月軸では動作しません"
#define MAIL_SUBJECT "トレードエントリー"
#define MAIL_UPTEXT "買い注文が入りました"
#define MAIL_DOWNTEXT "売り注文が入りました"

// Input parameters
input double Lots = DEFAULT_LOTS;      // 注文ロット数
input int Slippage = DEFAULT_SLIPPAGE; // 許容スリッページ（ポイント）
input bool EarlyTradeOption = false;   // 先行トレンド売買切替
input int WaitingCounts = 1;           // トレンド待ち回数
input bool SendML = false;             // エントリー時のメール送信

 
// Global parameters
int Ticket = -1;                  //　チケット番号
unsigned char Position = NONE_POSITION;   // ポジションフラグ
string Indicator_Name = "MACD_test";
int EarlyLineIndex = 0;
int MACDLineIndex = 2;          // 2:上位時間軸MACD
int ReferLineIndex = 7;         // 7:参考MACD　上昇フラグ　上昇時のみデータが入る。
datetime MainOldTime;           // メイン時間軸更新時間
datetime SubOldTime;            // サブ時間軸更新時間
int UpCounter = 0;              // トレンド待ちエントリー用UPカウンター
int DownCounter = 0;            // トレンド待ちエントリー用Downカウンター 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- check parameters
   if(checkPeriod()){
      Print(PERIOD_ERROR_MESSAGE);
      return (INIT_FAILED);
   }

   ObjectsDeleteAll();
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
   bool firstcheck = true, beforeposition;
   // Get MACD data
   double macd0 = iCustom(_Symbol, 0, Indicator_Name, MACDLineIndex, 0);
   double macd1 = iCustom(_Symbol, 0, Indicator_Name, MACDLineIndex, 1);
   
   double earlymacd0 = iCustom(_Symbol, 0, Indicator_Name, EarlyLineIndex, 0);
   double earlymacd1 = iCustom(_Symbol, 0, Indicator_Name, EarlyLineIndex, 1);
   
   // Get ReferMacd
   double refermacdup = iCustom(_Symbol, 0, Indicator_Name, ReferLineIndex, 0);

   datetime dt[], dt1[];
   int subperiod[2];

   getUpperPeriod(subperiod);
   ArrayCopySeries(dt1, MODE_TIME, Symbol(), subperiod[0]);

   // Main time axis(One on the time axis)
   if(dt1[0] != MainOldTime){
      MainOldTime = dt1[0];
      if(firstcheck){
         maintrade(macd0, macd1, refermacdup);
         // EarlyTrade is first entry only.
         if(EarlyTradeOption){ firstcheck = false; }
      }
   }// if(Time[0] != MainOldTime)
   
   // Early trade mode
   if(EarlyTradeOption && (firstcheck == false)){
      if(SubOldTime != Time[0]){
          SubOldTime = Time[0];
          beforeposition = Position;
          maintrade(earlymacd0, earlymacd1, refermacdup);
          // Reset
          if(Position != beforeposition){ firstcheck = true; }
      }// if(dt1[0] != SubOldTime)
    }// if(EarlyTradeOption)

   return;
}
  
  
//+------------------------------------------------------------------+

void getUpperPeriod(int &upperperiod[2])// [0]: One on the time axis [1]: two on the time axis
{
   switch(Period())
     {
      case PERIOD_M1:
         upperperiod[0] = PERIOD_M5;
         upperperiod[1] = PERIOD_M15;
         break;

      case PERIOD_M5:
         upperperiod[0] = PERIOD_M15;
         upperperiod[1] = PERIOD_M30;
         break;

      case PERIOD_M15:
         upperperiod[0] = PERIOD_M30;
         upperperiod[1] = PERIOD_H1;
         break;

      case PERIOD_M30:
         upperperiod[0] = PERIOD_H1;
         upperperiod[1] = PERIOD_H4;
         break;

      case PERIOD_H1:
         upperperiod[0] = PERIOD_H4;
         upperperiod[1] = PERIOD_D1;
         break;

      case PERIOD_H4:
         upperperiod[0] = PERIOD_D1;
         upperperiod[1] = PERIOD_W1;
         break;

      case PERIOD_D1:
         upperperiod[0] = PERIOD_W1;
         upperperiod[1] = PERIOD_MN1;
         break;

      case PERIOD_W1:
         upperperiod[0] = PERIOD_MN1;
         upperperiod[1] = PERIOD_CURRENT;
         break;

      case PERIOD_MN1:
         default:
         upperperiod[0] = PERIOD_CURRENT;
         upperperiod[1] = PERIOD_CURRENT;
         break;
     }
   return;
  }
//+------------------------------------------------------------------+

// this function look and set to globals
void maintrade(double macd0,        // MACD 1st data
               double macd1,        // MACD 2nd data
               double refermacdup){ // MACD 3rd refer data(EMPTY_VALUE or input Referaxis data)
   bool ret;
   if(macd0 > macd1){
      // Buy position
      UpCounter++;
      DownCounter = 0;
      if(!is_zero(Position & BUY_POSITION)){ return; }
      if(!is_zero(Position & SELL_POSITION)){
         if(OrderSelect(Ticket, SELECT_BY_TICKET)){
            ret = OrderClose(Ticket, OrderLots(), OrderClosePrice(), Slippage);
            if(ret){
               createline(CLOSE);
               Ticket = -1;
               Position = NONE_POSITION;
               UpCounter = DownCounter = 0;
            }
         }
      }// if(!is_zero(Position & SELL_POSITION))

      if((UpCounter >= WaitingCounts+1)&&(refermacdup != EMPTY_VALUE)){
         if(SendML){ SendMail( MAIL_SUBJECT, MAIL_UPTEXT ); }
         Ticket = OrderSend(_Symbol, OP_BUY, Lots, Ask, Slippage, 0, 0);
         if(Ticket != -1){
            createline(ENTRY);
            Position = BUY_POSITION;
         }
      }
   }else if(macd0 < macd1){// else if(macd0 > macd1)
      // Sell position
      DownCounter++;
      UpCounter = 0;
      if(!is_zero(Position & SELL_POSITION)){ return; }
      if(!is_zero(Position & BUY_POSITION)){
         if(OrderSelect(Ticket, SELECT_BY_TICKET)){
            ret = OrderClose(Ticket, OrderLots(), OrderClosePrice(), Slippage);
            if(ret){
               createline(CLOSE);
               Ticket = -1;
               Position = NONE_POSITION;
               UpCounter = DownCounter = 0;
            }         
         }
      }// if(!is_zero(Position & BUY_POSITION))
      if((DownCounter >= WaitingCounts+1)&&refermacdup == EMPTY_VALUE){
         if(SendML){ SendMail( MAIL_SUBJECT, MAIL_DOWNTEXT ); }         
         Ticket = OrderSend(_Symbol, OP_SELL, Lots, Bid, Slippage, 0, 0);      
         if(Ticket != -1){
            createline(ENTRY);
            Position = SELL_POSITION;
         }
      }
   }// else
   // macd0 == macd1 trading through
   return;
}

//+------------------------------------------------------------------+

void createline(int  mode){
   string objname;
   switch(mode){
      case ENTRY:
            objname = "Entry:" + IntegerToString(Time[0]);
            ObjectCreate(objname, OBJ_VLINE, 0, Time[0], 0);
            ObjectSetInteger(0, objname, OBJPROP_COLOR, clrYellow);          
         break;

      case CLOSE:
            objname = "Close:" + IntegerToString(Time[0]);
            ObjectCreate(objname, OBJ_VLINE, 0, Time[0], 0);
            ObjectSetInteger(0, objname, OBJPROP_COLOR, clrRed);                   
         break;

      default:
         break;
   }
}

//+------------------------------------------------------------------+
bool checkPeriod(){
   int periodnum = Period();
   if(periodnum == PERIOD_W1 || periodnum == PERIOD_MN1){ return true; }
   return false;
}

//+------------------------------------------------------------------+
bool is_zero( int a ) { return a == 0; }
