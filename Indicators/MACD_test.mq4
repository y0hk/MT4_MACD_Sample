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
#property indicator_buffers 7
#property indicator_plots   7
#property indicator_color1 Red
#property indicator_color2 Green
#property indicator_color3 Aqua
#property indicator_color4 White
#property indicator_color5 Black
#property indicator_color6 Red
#property indicator_color7 Green

#property indicator_width2 2
#property indicator_width3 2
#property indicator_width6 2
#property indicator_width7 2


double Macd[], Signal[], Histogram[], MacdUp[], ReferMacd[], ReferMacdDown[], ReferMacdUp[];

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
extern int FastPeriod   = 12; // EMA（短期）
extern int SlowPeriod   = 26; // EMA（長期）
extern int SignalPeriod = 9;  // シグナル期間

extern ENUM_APPLIED_PRICE AppliedPrice = PRICE_CLOSE; // 適用価格
extern ENUM_MA_METHOD     MacdMethod   = MODE_EMA;    // MA移動平均メソッド
extern ENUM_MA_METHOD     SignalMethod = MODE_EMA;    // Signal移動平均メソッド
extern ENUM_TIMEFRAMES    ReferTimeframe = PERIOD_D1; // +-参考指標時間軸
extern double  referaxis = -0.5;                      // 参考軸配置位置

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, Macd);
	SetIndexStyle(0, DRAW_LINE);
	SetIndexLabel(0, StringFormat("MACD(Fast:%d, Slow:%d)", FastPeriod, SlowPeriod));
	SetIndexDrawBegin(0, SlowPeriod);

   SetIndexBuffer(1, MacdUp);
	SetIndexStyle(1, DRAW_LINE);
//	SetIndexLabel(1, StringFormat("MACD UpSide",));
	SetIndexLabel(1, NULL);
	SetIndexDrawBegin(1, SlowPeriod);

	SetIndexBuffer(2, Signal);
	SetIndexStyle(2, DRAW_LINE);
	SetIndexLabel(2, StringFormat("Signal:%d", SignalPeriod));
	SetIndexDrawBegin(2, SlowPeriod + SignalPeriod);

	SetIndexBuffer(3, Histogram);
	SetIndexStyle(3, DRAW_HISTOGRAM, STYLE_SOLID, 2);
	SetIndexLabel(3, "Histogram(Up)");
	SetIndexDrawBegin(3, SlowPeriod + SignalPeriod);
	
	SetIndexBuffer(4, ReferMacd);
	SetIndexStyle(4, DRAW_LINE);
	SetIndexLabel(4, "Reference MACD");
	SetIndexDrawBegin(4, SlowPeriod);

	SetIndexBuffer(5, ReferMacdDown);
	SetIndexStyle(5, DRAW_LINE);
	SetIndexLabel(5, "Reference Axis");
	SetIndexDrawBegin(5, SlowPeriod);
	
	SetIndexBuffer(6, ReferMacdUp);
	SetIndexStyle(6, DRAW_LINE);
	SetIndexLabel(6, "Reference Axis(Up)");
	SetIndexDrawBegin(6, SlowPeriod);
	
	IndicatorShortName(StringFormat("MACD(Fast:%d, Slow:%d, Signal:%d)", FastPeriod, SlowPeriod, SignalPeriod));
	
//---
   return(INIT_SUCCEEDED);
  }
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
	int limit = rates_total - MathMax(prev_calculated, 1);
	
	// MACD
	for (int i = 0; i < limit; i++){
	   Macd[i]=iMA(NULL, PERIOD_CURRENT, FastPeriod, 0, MacdMethod, AppliedPrice, i)
	         -iMA(NULL, PERIOD_CURRENT, SlowPeriod, 0, MacdMethod, AppliedPrice, i);
	   ReferMacd[i]=iMA(NULL, ReferTimeframe, FastPeriod, 0, MacdMethod, AppliedPrice, i)
	         -iMA(NULL, ReferTimeframe, SlowPeriod, 0, MacdMethod, AppliedPrice, i);
	}
	
	// MACD Up/Down
	for (int i = limit-1; i >= 0; i--){
		if(Macd[i] > Macd[i+1]){
		   // Switching Up
		   if(MacdUp[i+1] == EMPTY_VALUE){ MacdUp[i+1] = Macd[i+1]; }
		   MacdUp[i] = Macd[i];
		}
		
		ReferMacdDown[i] = referaxis;
		if(ReferMacd[i] > ReferMacd[i+1]){
		   // Switching Up
		   if(ReferMacdUp[i+1] == EMPTY_VALUE){ ReferMacdUp[i+1] = referaxis; }
		   ReferMacdUp[i] = referaxis;		   		   
		}
	}
		
   // Signal and Histogram
	for (int i = 0; i < limit; i++){
      Signal[i] = iMAOnArray(Macd, 0, SignalPeriod, 0, SignalMethod, i);
		Histogram[i] = Macd[i] - Signal[i];
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
