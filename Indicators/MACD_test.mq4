//+------------------------------------------------------------------+
//|                                                    MACD_test.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "MACD test"
#property strict
#property indicator_separate_window


//+------------------------------------------------------------------+
//| Indicator settings and buffers                                   |
//+------------------------------------------------------------------+
#property indicator_buffers 9
#property indicator_plots   8
#property indicator_color1 Green // MACD
#property indicator_color2 Red   // MACD Updside
#property indicator_color3 Green // MACD 1Upper
#property indicator_color4 Red   // MACD 1Upper Upside
#property indicator_color5 Aqua  // Signal
#property indicator_color6 White // Histgram
#property indicator_color7 Green // ReferMACD 2Upper
#property indicator_color8 Red   // ReferMACD 2Upper Upside

#property indicator_width1 3
#property indicator_width2 3
#property indicator_width7 2
#property indicator_width8 2

#define PERIOD_ERROR_MESSAGE "週軸及び月軸では動作しません"

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
extern int FastPeriod   = 12; // EMA（短期）
extern int SlowPeriod   = 26; // EMA（長期）
extern int SignalPeriod = 9;  // シグナル期間

extern ENUM_APPLIED_PRICE AppliedPrice = PRICE_CLOSE; // 適用価格
extern ENUM_MA_METHOD     MacdMethod   = MODE_EMA;    // MA移動平均メソッド
extern ENUM_MA_METHOD     SignalMethod = MODE_EMA;    // Signal移動平均メソッド
//extern ENUM_TIMEFRAMES    ReferTimeframe = PERIOD_D1; // +-参考指標時間軸
extern double  Referaxis=0.0;                       // 参考軸配置位置

double Macd[],MacdUpside[],Macd_1up[], Macd_1upUpside[],Signal[],Histogram[],ReferMacdDown[],ReferMacdUp[],Macd_2up[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- check parameters
   if(checkPeriod()){
      Print(PERIOD_ERROR_MESSAGE);
      return (INIT_FAILED);
   }
   
//--- indicator buffers mapping
   SetIndexBuffer(0,Macd);
   SetIndexStyle(0,DRAW_LINE);
   SetIndexLabel(0,StringFormat("MACD(Fast:%d, Slow:%d)",FastPeriod,SlowPeriod));
   SetIndexDrawBegin(0, SlowPeriod);
   
   SetIndexBuffer(1,MacdUpside);
   SetIndexStyle(1,DRAW_LINE);
//	SetIndexLabel(1, StringFormat("MACD UpSide",));
   SetIndexLabel(1,NULL);
   SetIndexDrawBegin(1, SlowPeriod);
   
   SetIndexBuffer(2, Macd_1up);
   SetIndexStyle(2, DRAW_LINE);
   SetIndexLabel(2, "Upper MACD");
   SetIndexDrawBegin(2, SlowPeriod);

   SetIndexBuffer(3,Macd_1upUpside);
   SetIndexStyle(3,DRAW_LINE);
//	SetIndexLabel(3, StringFormat("Upper MACD UpSide",));
   SetIndexLabel(3,NULL);
   SetIndexDrawBegin(3, SlowPeriod);

   SetIndexBuffer(4, Signal);
   SetIndexStyle(4, DRAW_LINE);
   SetIndexLabel(4, StringFormat("Signal:%d",SignalPeriod));
   SetIndexDrawBegin(4, SlowPeriod+SignalPeriod);

   SetIndexBuffer(5,Histogram);
   SetIndexStyle(5,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexLabel(5,"Histogram(Up)");
   SetIndexDrawBegin(5,SlowPeriod+SignalPeriod);

   SetIndexBuffer(6,ReferMacdDown);
   SetIndexStyle(6,DRAW_LINE);
   SetIndexLabel(6,"Reference Axis");
   SetIndexDrawBegin(6,SlowPeriod);

   SetIndexBuffer(7, ReferMacdUp);
   SetIndexStyle(7, DRAW_LINE);
   SetIndexLabel(7, "Reference Axis(Up)");
   SetIndexDrawBegin( 7,SlowPeriod);

   SetIndexBuffer(8, Macd_2up);

   IndicatorShortName(StringFormat("MACD(Fast:%d, Slow:%d, Signal:%d)",FastPeriod,SlowPeriod,SignalPeriod));

//---
   return(INIT_SUCCEEDED);
  }

double work_1up, work_2up;
bool upnext = false;

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---

   int limit=rates_total-MathMax(prev_calculated,1);
   int nextperiod[2];
   int max_1up,max_2up;
   datetime timearray_1up[],timearray_2up[];

   getUpperPeriod(nextperiod);

   max_1up = ArrayCopySeries(timearray_1up, MODE_TIME, Symbol(), nextperiod[0]);
   max_2up = ArrayCopySeries(timearray_2up, MODE_TIME, Symbol(), nextperiod[1]);

   if(prev_calculated == 0){// Create an indicator to date.
      // MACD   
      for(int i=0,i1up=0,i2up=0; i<limit; i++){
         Macd[i]=iMA(NULL, PERIOD_CURRENT, FastPeriod, 0, MacdMethod, AppliedPrice, i)
                -iMA(NULL,PERIOD_CURRENT,SlowPeriod,0,MacdMethod,AppliedPrice,i);
//         Print("MACD:", DoubleToString(Macd[i]));
              
         // 1up MACD
         if((Time[i]<timearray_1up[i1up]) && (i1up < max_1up-1)){ i1up++; }      
         Macd_1up[i]=iMA(NULL,nextperiod[0],FastPeriod,0,MacdMethod,AppliedPrice,i1up)
                    -iMA(NULL,nextperiod[0],SlowPeriod,0,MacdMethod,AppliedPrice,i1up);         
         if(i == 0){ work_1up = Macd_1up[i]; } // backup new data.
      
         // debug_log
//         if(i1up < max_1up-1){
//            Print("■■上位時間軸の時間：", TimeToString(timearray_1up[i1up]));
//         }
//         Print("■■上位時間軸のMACD:", DoubleToString(Macd_1up[i]));

         // 2up MACD
         if((Time[i]<timearray_2up[i2up]) && (i2up<max_2up-1)){ i2up++; }      
         Macd_2up[i]=iMA(NULL,nextperiod[1],FastPeriod,0,MacdMethod,AppliedPrice,i2up)
                    -iMA(NULL,nextperiod[1],SlowPeriod,0,MacdMethod,AppliedPrice,i2up);
         if(i == 0){ work_2up = Macd_1up[i]; } // backup new data.
      }// for(int i=0,i1up=0,i2up=0; i<limit; i++)

      // MACD Updata Setting on baseline
      for(int i=limit-1; i>=0; i--){
         if(Macd[i] > Macd[i+1]){
         // Switching Up
            if(MacdUpside[i+1]==EMPTY_VALUE){ MacdUpside[i+1]=Macd[i+1]; }
            MacdUpside[i]=Macd[i];
         }
      
         // for switching upside color
         if(Macd_1up[i] > Macd_1up[i+1]){
            // Switching Up
            if(Macd_1upUpside[i+1]==EMPTY_VALUE){ Macd_1upUpside[i+1]=Macd_1up[i+1]; }
            Macd_1upUpside[i]=Macd_1up[i];
            upnext = true;
         }else if(Macd_1up[i] < Macd_1up[i+1]){
            upnext = false;
         }else{
            if(upnext){ Macd_1upUpside[i]=Macd_1up[i]; }
         }

         // for refer base +/-
         ReferMacdDown[i]=Referaxis;
         ReferMacdUp[i]=EMPTY_VALUE;

         if(Macd_2up[i]==Macd_2up[i+1]){ // Trend continuation
            ReferMacdUp[i]=ReferMacdUp[i+1];
         }else if(Macd_2up[i]>Macd_2up[i+1]){
            // Switching up
            if(ReferMacdUp[i+1]==EMPTY_VALUE){ ReferMacdUp[i+1]=Referaxis; }
            ReferMacdUp[i]=Referaxis;
         }
      }// for(int i=limit-1; i>=0; i--)

      // Signal and Histogram
      for(int i=0; i<limit; i++){
         Signal[i]=iMAOnArray(Macd,0,SignalPeriod,0,SignalMethod,i);
         Histogram[i]=Macd[i]-Signal[i];
      }
   }else{// if(prev_calculated == 0) 
      if(limit > 0){ // Create an indicator now.
         // MACD
         Macd[0]=iMA(NULL, PERIOD_CURRENT, FastPeriod, 0, MacdMethod, AppliedPrice, 0)
                -iMA(NULL, PERIOD_CURRENT, SlowPeriod, 0, MacdMethod, AppliedPrice, 0);
//         Print("MACD:", DoubleToString(Macd[0]));

         // 1up MACD         
         if(Time[0] == timearray_1up[0]){
            work_1up = iMA(NULL, nextperiod[0], FastPeriod, 0, MacdMethod, AppliedPrice, 0)
                      -iMA(NULL, nextperiod[0], SlowPeriod, 0, MacdMethod, AppliedPrice, 0);
            Print("■■上位時間軸の時間：", TimeToString(timearray_1up[0]));
            Print("■■上位時間軸のMACD:", DoubleToString(work_1up));
         }
         Macd_1up[0] = work_1up;
         
         // 2up MACD
         if(Time[0] == timearray_2up[0]){
            work_2up = iMA(NULL, nextperiod[1], FastPeriod, 0, MacdMethod, AppliedPrice, 0)
                      -iMA(NULL, nextperiod[1], SlowPeriod, 0, MacdMethod, AppliedPrice, 0);
         }
         Macd_2up[0] = work_2up;

         // MACD Updata Setting on baseline
         if(Macd[0] > Macd[1]){
         // Switching Up
            if(MacdUpside[1]==EMPTY_VALUE){ MacdUpside[1]=Macd[1]; }
            MacdUpside[0]=Macd[0];
         }
      
         // for switching upside color
         if(Macd_1up[0] > Macd_1up[1]){
            // Switching Up
            if(Macd_1upUpside[1]==EMPTY_VALUE){ Macd_1upUpside[1]=Macd_1up[1]; }
            Macd_1upUpside[0]=Macd_1up[0];
            upnext = true;            
         }else if(Macd_1up[0] < Macd_1up[1]){
            upnext = false;
         }else{
            if(upnext){ Macd_1upUpside[0] = Macd_1up[0]; }
         }

         // for refer base +/-
         ReferMacdDown[0]=Referaxis;
         ReferMacdUp[0]=EMPTY_VALUE;

         if(Macd_2up[0]==Macd_2up[1]){ // Trend continuation
            ReferMacdUp[0]=ReferMacdUp[1];
         }else if(Macd_2up[0] > Macd_2up[1]){
            // Switching up
            if(ReferMacdUp[1]==EMPTY_VALUE){ ReferMacdUp[1]=Referaxis; }
            ReferMacdUp[0]=Referaxis;
         }
         
         // Signal and Histogram
         Signal[0] = iMAOnArray(Macd, 0, SignalPeriod, 0, SignalMethod, 0);
         Histogram[0] = Macd[0] - Signal[0];         
      }
   }// else

//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
bool checkPeriod(){
   int periodnum = Period();
   if(periodnum == PERIOD_W1 || periodnum == PERIOD_MN1){ return true; }
   return false;
}


//+------------------------------------------------------------------+

void getUpperPeriod(int &upperperiod[2])
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
