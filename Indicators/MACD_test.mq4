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
#property indicator_buffers 5
#property indicator_plots   5
#property indicator_color1 Black
#property indicator_color2 Green
#property indicator_color3 Red
#property indicator_color4 Aqua
#property indicator_color5 White

#property indicator_width2 2
#property indicator_width3 2

double Macd[], Signal[], Histogram[], MacdUp[], MacdDown[];


//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
extern int FastPeriod   = 12; // EMA（短期）
extern int SlowPeriod   = 26; // EMA（長期）
extern int SignalPeriod = 9;  // シグナル期間

extern ENUM_APPLIED_PRICE AppliedPrice = PRICE_CLOSE;
extern ENUM_MA_METHOD     MacdMethod   = MODE_EMA;
extern ENUM_MA_METHOD     SignalMethod = MODE_EMA;

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
	
   SetIndexBuffer(2, MacdDown);
	SetIndexStyle(2, DRAW_LINE);
//	SetIndexLabel(2, StringFormat("MACD DownSide",));
	SetIndexLabel(2, NULL);
	SetIndexDrawBegin(2, SlowPeriod);

	SetIndexBuffer(3, Signal);
	SetIndexStyle(3, DRAW_LINE);
	SetIndexLabel(3, StringFormat("Signal:%d", SignalPeriod));
	SetIndexDrawBegin(3, SlowPeriod + SignalPeriod);

	SetIndexBuffer(4, Histogram);
	SetIndexStyle(4, DRAW_HISTOGRAM, STYLE_SOLID, 2);
	SetIndexLabel(4, "Histogram(Up)");
	SetIndexDrawBegin(4, SlowPeriod + SignalPeriod);

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
	   Macd[i]=iMA(NULL, 0, FastPeriod, 0, MacdMethod, AppliedPrice, i)-iMA(NULL, 0, SlowPeriod, 0, MacdMethod, AppliedPrice, i);
	}
//	Print("Macd[0]=", Macd[0]);
//	Print("Macd[1]=", Macd[1]);
//	Print("Macd[2]=", Macd[2]);
	
//	Print("MacdUp[0]=", MacdUp[0]);
//	Print("MacdUp[1]=", MacdUp[1]);
//	Print("MacdUp[2]=", MacdUp[2]);

//	Print("MacdDown[0]=", MacdDown[0]);
//	Print("MacdDown[1]=", MacdDown[1]);
//	Print("MacdDown[2]=", MacdDown[2]);
	
	// MACD Up/Down
	for (int i = limit-1; i >= 0; i--){
		if(Macd[i] > Macd[i+1]){
		   // Switching Up/Down
		   if(MacdUp[i+1] == EMPTY_VALUE){ MacdUp[i+1] = Macd[i+1]; }
		   MacdUp[i] = Macd[i];
		   MacdDown[i] = EMPTY_VALUE;
		}else if(Macd[i] < Macd[i+1]){
		   // Switching Up/Down
		   if(MacdDown[i+1] == EMPTY_VALUE){ MacdDown[i+1] = Macd[i+1]; }
		   MacdUp[i] = EMPTY_VALUE;
		   MacdDown[i] = Macd[i];		   
		}else{
		   if(MacdUp[i+1] == EMPTY_VALUE){
   		   MacdUp[i] = EMPTY_VALUE;
   		   MacdDown[i] = Macd[i];
   		}else{
   		   MacdUp[i] = Macd[i];
		      MacdDown[i] = EMPTY_VALUE;
   		}		      
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
