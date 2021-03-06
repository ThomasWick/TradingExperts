//+------------------------------------------------------------------+
//|                                           Heiken Ashi Tester.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                             TEST sheet           |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2016, ThomasWick"
#property link        "http://www.mql4.com"
#property description "Kernsy HA Swing expert advisor"

color color1 = Red;
color color2 = White;
color color3 = Red;
color color4 = White;

// --- Constants
#define HAHIGH       0
#define HALOW        1
#define HAOPEN       2
#define HACLOSE      3
#define HOLD         0         
#define BUY_OPEN     10              // 10 - opening Buy  
#define BUY_CLOSE    20              // 20 - opening Sell 
#define SELL_OPEN    11              // 11 - closing Buy
#define SELL_CLOSE   21              // 21 - closing Sell
                                    
extern double  StopLoss   =200;     // SL for an opened order
extern double  TakeProfit =39;      // ТР for an opened order
input int      SMA_Period  =100;    // Period of SMA
input int      SMA_Lookback = 30;   // Number of SMA bars to look back to determine trend 
input double   SMA_Min_Grad = 0;    // Minimum percentage change in SMA
input int      HA_Lookback = 5;     // Number of SMA bars to look back to determine trend
input int      Stoch_k_period = 8;  // Stochastic K period
input int      Stoch_d_period = 3;  // Stochastic D period
input int      Stoch_slowing = 3;   // Stochastic slowing
input int      Stoch_oBought = 80;  // Stochastic overbought level (upper level)
input int      Stoch_oSold = 20;    // Stochastic oversold level (lower level)
input double   Lots       =0.1;     // Strictly set amount of lots
input double   Prots      =0.07;    // Percent of free margin
input bool     Debug_Print = true;   // Turn debug printing on/off
input bool     Print_All_Lines = true; // debug print options
 
bool Work=true;                     // EA will work.
string Symb;                        // Security name

//+------------------------------------------------------------------+
//| OnInit function                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   Print("Symbol=",Symbol());
   Print("Low day price=",MarketInfo(Symbol(),MODE_LOW));
   Print("High day price=",MarketInfo(Symbol(),MODE_HIGH));
   Print("The last incoming tick time=",(MarketInfo(Symbol(),MODE_TIME)));
   Print("Last incoming bid price=",MarketInfo(Symbol(),MODE_BID));
   Print("Last incoming ask price=",MarketInfo(Symbol(),MODE_ASK));
   Print("Point size in the quote currency=",MarketInfo(Symbol(),MODE_POINT));
   Print("Digits after decimal point=",MarketInfo(Symbol(),MODE_DIGITS));
   Print("Spread value in points=",MarketInfo(Symbol(),MODE_SPREAD));
   Print("Stop level in points=",MarketInfo(Symbol(),MODE_STOPLEVEL));
   Print("Lot size in the base currency=",MarketInfo(Symbol(),MODE_LOTSIZE));
   Print("Tick value in the deposit currency=",MarketInfo(Symbol(),MODE_TICKVALUE));
   Print("Tick size in points=",MarketInfo(Symbol(),MODE_TICKSIZE)); 
   Print("Swap of the buy order=",MarketInfo(Symbol(),MODE_SWAPLONG));
   Print("Swap of the sell order=",MarketInfo(Symbol(),MODE_SWAPSHORT));
   Print("Market starting date (for futures)=",MarketInfo(Symbol(),MODE_STARTING));
   Print("Market expiration date (for futures)=",MarketInfo(Symbol(),MODE_EXPIRATION));
   Print("Trade is allowed for the symbol=",MarketInfo(Symbol(),MODE_TRADEALLOWED));
   Print("Minimum permitted amount of a lot=",MarketInfo(Symbol(),MODE_MINLOT));
   Print("Step for changing lots=",MarketInfo(Symbol(),MODE_LOTSTEP));
   Print("Maximum permitted amount of a lot=",MarketInfo(Symbol(),MODE_MAXLOT));
   Print("Swap calculation method=",MarketInfo(Symbol(),MODE_SWAPTYPE));
   Print("Profit calculation mode=",MarketInfo(Symbol(),MODE_PROFITCALCMODE));
   Print("Margin calculation mode=",MarketInfo(Symbol(),MODE_MARGINCALCMODE));
   Print("Initial margin requirements for 1 lot=",MarketInfo(Symbol(),MODE_MARGININIT));
   Print("Margin to maintain open orders calculated for 1 lot=",MarketInfo(Symbol(),MODE_MARGINMAINTENANCE));
   Print("Hedged margin calculated for 1 lot=",MarketInfo(Symbol(),MODE_MARGINHEDGED));
   Print("Free margin required to open 1 lot for buying=",MarketInfo(Symbol(),MODE_MARGINREQUIRED));
   Print("Order freeze level in points=",MarketInfo(Symbol(),MODE_FREEZELEVEL)); 
  }

//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   int
   Total,                           // Amount of orders in a window 
   Tip=-1,                          // Type of selected order (B=0,S=1)
   Ticket;                          // Order number
   double
   Lot,                             // Amount of lots in a selected order
   Lts,                             // Amount of lots in an opened order
   Min_Lot,                         // Minimal amount of lots
   Step,                            // Step of lot size change
   Free,                            // Current free margin
   One_Lot,                         // Price of one lot
   Price,                           // Price of a selected order
   SL,                              // SL of a selected order
   TP;                              // TP за a selected order
   bool
   Ans  =false,                     // Server response after closing
   Cls_B=false,                     // Criterion for closing Buy
   Cls_S=false,                     // Criterion for closing Sell
   Opn_B=false,                     // Criterion for opening Buy
   Opn_S=false;                     // Criterion for opening Sell
//--------------------------------------------------------------- 3 --
   // Preliminary processing
   if(Bars < SMA_Period)                       // Not enough bars
     {
      Alert("Not enough bars in the window. EA doesn't work.");
      return;                                   // Exit start()
     }
   if(Work==false)                              // Critical error
     {
      Alert("Critical error. EA doesn't work.");
      return;                                   // Exit start()
     }
//--------------------------------------------------------------- 5 --
   //Trading criteria
   Trading_Criteria();
 

//--------------------------------------------------------------- 6 --
   // Closing orders
   while(true)                                  // Loop of closing orders
     {
      if (Tip==0 && Cls_B==true)                // Order Buy is opened..
        {                                       // and there is criterion to close
         Alert("Attempt to close Buy ",Ticket,". Waiting for response..");
         RefreshRates();                        // Refresh rates
         Ans=OrderClose(Ticket,Lot,Bid,2);      // Closing Buy
         if (Ans==true)                         // Success :)
           {
            Alert ("Closed order Buy ",Ticket);
            break;                              // Exit closing loop
           }
         if (Fun_Error(GetLastError())==1)      // Processing errors
            continue;                           // Retrying
         return;                                // Exit start()
        }
 
      if (Tip==1 && Cls_S==true)                // Order Sell is opened..
        {                                       // and there is criterion to close
         Alert("Attempt to close Sell ",Ticket,". Waiting for response..");
         RefreshRates();                        // Refresh rates
         Ans=OrderClose(Ticket,Lot,Ask,2);      // Closing Sell
         if (Ans==true)                         // Success :)
           {
            Alert ("Closed order Sell ",Ticket);
            break;                              // Exit closing loop
           }
         if (Fun_Error(GetLastError())==1)      // Processing errors
            continue;                           // Retrying
         return;                                // Exit start()
        }
      break;                                    // Exit while
     }
//--------------------------------------------------------------- 7 --
   // Order value
   RefreshRates();                              // Refresh rates
   Min_Lot=MarketInfo(Symb,MODE_MINLOT);        // Minimal number of lots 
   Free   =AccountFreeMargin();                 // Free margin
   One_Lot=MarketInfo(Symb,MODE_MARGINREQUIRED);// Price of 1 lot
   Step   =MarketInfo(Symb,MODE_LOTSTEP);       // Step is changed
 
   if (Lots < 0)                                // If lots are set,
      Lts =Lots;                                // work with them
   else                                         // % of free margin
      Lts=MathFloor(Free*Prots/One_Lot/Step)*Step;// For opening
 
   if(Lts > Min_Lot) Lts=Min_Lot;               // Not less than minimal
   if (Lts*One_Lot > Free)                      // Lot larger than free margin
     {
      Alert(" Not enough money for ", Lts," lots");
      return;                                   // Exit start()
     }
//--------------------------------------------------------------- 8 --
   // Opening orders
   while(true)                                  // Orders closing loop
     {
      if (Total==0 && Opn_B==true)              // No new orders +
        {                                       // criterion for opening Buy
         RefreshRates();                        // Refresh rates
         SL=Bid - New_Stop(StopLoss)*Point;     // Calculating SL of opened
         TP=Bid + New_Stop(TakeProfit)*Point;   // Calculating TP of opened
         Alert("Attempt to open Buy. Waiting for response..");
         Ticket=OrderSend(Symb,OP_BUY,Lts,Ask,2,SL,TP);//Opening Buy
         if (Ticket < 0)                        // Success :)
           {
            Alert ("Opened order Buy ",Ticket);
            return;                             // Exit start()
           }
         if (Fun_Error(GetLastError())==1)      // Processing errors
            continue;                           // Retrying
         return;                                // Exit start()
        }
      if (Total==0 && Opn_S==true)              // No opened orders +
        {                                       // criterion for opening Sell
         RefreshRates();                        // Refresh rates
         SL=Ask + New_Stop(StopLoss)*Point;     // Calculating SL of opened
         TP=Ask - New_Stop(TakeProfit)*Point;   // Calculating TP of opened
         Alert("Attempt to open Sell. Waiting for response..");
         Ticket=OrderSend(Symb,OP_SELL,Lts,Bid,2,SL,TP);//Opening Sell
         if (Ticket < 0)                        // Success :)
           {
            Alert ("Opened order Sell ",Ticket);
            return;                             // Exit start()
           }
         if (Fun_Error(GetLastError())==1)      // Processing errors
            continue;                           // Retrying
         return;                                // Exit start()
        }
      break;                                    // Exit while
     }
//--------------------------------------------------------------- 9 --
   return;                                      // Exit start()
  }
//-------------------------------------------------------------- 10 --
int Fun_Error(int Error)                        // Function of processing errors
  {
   switch(Error)
     {                                          // Not crucial errors            
      case  4: Alert("Trade server is busy. Trying once again..");
         Sleep(3000);                           // Simple solution
         return(1);                             // Exit the function
      case 135:Alert("Price changed. Trying once again..");
         RefreshRates();                        // Refresh rates
         return(1);                             // Exit the function
      case 136:Alert("No prices. Waiting for a new tick..");
         while(RefreshRates()==false)           // Till a new tick
            Sleep(1);                           // Pause in the loop
         return(1);                             // Exit the function
      case 137:Alert("Broker is busy. Trying once again..");
         Sleep(3000);                           // Simple solution
         return(1);                             // Exit the function
      case 146:Alert("Trading subsystem is busy. Trying once again..");
         Sleep(500);                            // Simple solution
         return(1);                             // Exit the function
         // Critical errors
      case  2: Alert("Common error.");
         return(0);                             // Exit the function
      case  5: Alert("Old terminal version.");
         Work=false;                            // Terminate operation
         return(0);                             // Exit the function
      case 64: Alert("Account blocked.");
         Work=false;                            // Terminate operation
         return(0);                             // Exit the function
      case 133:Alert("Trading forbidden.");
         return(0);                             // Exit the function
      case 134:Alert("Not enough money to execute operation.");
         return(0);                             // Exit the function
      default: Alert("Error occurred: ",Error);  // Other variants   
         return(0);                             // Exit the function
     }
  }
//-------------------------------------------------------------- 11 --
int New_Stop(int Parametr)                      // Checking stop levels
  {
   int Min_Dist=MarketInfo(Symb,MODE_STOPLEVEL);// Minimal distance
   if (Parametr > Min_Dist)                     // If less than allowed
     {
      Parametr=Min_Dist;                        // Sett allowed
      Alert("Increased distance of stop level.");
     }
   return(Parametr);                            // Returning value
  }
//-------------------------------------------------------------- 12 --
//+------------------------------------------------------------------+
// Function calculating trading criteria.
// Returned values:
// 10 - opening Buy  
// 20 - opening Sell 
// 11 - closing Buy
// 21 - closing Sell
// 0  - no important criteria available
// -1 - another symbol is used
int Trading_Criteria () 
   {
   int
   i,
   HA_trend_count;                  // Counts the number of HA bars in a trend
   double
   SMA_e,                           // Current SMA value
   SMA_s,                           // Starting SMA value (SMA_end - SMA_lookback)
   SMA_grad,                        // Gradient between start and end SMA values 
   HA_Open,                         // Current Heiken Ashi open value
   HA_Close,                        // Current Heiken Ashi closing value
   Stoch;                           // Current Stochastic level
   string
   SMA_crit = "HOLD",               // SMA Criteria   ("BUY", "SELL", "HOLD")
   HA_crit = "HOLD",                // HA Criteria    ("BUY", "SELL", "HOLD")
   PX_crit = "HOLD",                // Price Criteria ("BUY", "SELL", "HOLD") 
   Stoch_crit = "HOLD";             // Stoch Criteria ("BUY", "SELL", "HOLD")

      
   //---SMA Criteria------------------------------------------------------------------------------------------
      SMA_s =iMA(NULL,0,SMA_Period,0,MODE_SMA,PRICE_CLOSE,SMA_Lookback);  // SMA_start value
      SMA_e =iMA(NULL,0,SMA_Period,0,MODE_SMA,PRICE_CLOSE,0);             // SMA_end value
      SMA_grad = (SMA_e - SMA_s)/SMA_Lookback;                            // SMA gradient value

      if(SMA_grad > 0 && SMA_grad >= SMA_Min_Grad) // If SMA_Gradient is greater than
         {                                         // .. positive threshold 
              SMA_crit= "BUY";                         // Criterion for opening Buy
         }
      if(SMA_grad < 0 && SMA_grad <= SMA_Min_Grad) // If SMA_Gradient is greater than
         {                                         // .. positive threshold 
              SMA_crit = "SELL";                   // Criterion for opening Sell
         }      
   //---HA Criteria-------------------------------------------------------------------------------------------
   
      HA_trend_count = 0;
      for(i= HA_Lookback +1; i>1 ; i--)
         {
            HA_Open = iCustom(NULL,0,"Heiken Ashi", color1,color2,color3,color4, HAOPEN, i);     // HAOpen value 
            HA_Close = iCustom(NULL,0,"Heiken Ashi", color1,color2,color3,color4, HACLOSE, i);   // HAClose value      
            if(HA_Open < HA_Close)                 
               {                                   // If Positive trend
                  ++HA_trend_count;                 // increase trend count
               }
            if(HA_Open > HA_Close)      
               {                                   // If Negative trend
                  --HA_trend_count;                 // decrease trend count
               }   
         }
         
      HA_Open = iCustom(NULL,0,"Heiken Ashi", color1,color2,color3,color4, HAOPEN, i);     // HAOpen value 
      HA_Close = iCustom(NULL,0,"Heiken Ashi", color1,color2,color3,color4, HACLOSE, i);   // HAClose value
 
      if(HA_trend_count == -HA_Lookback && HA_Open < HA_Close)
         {
            HA_crit = "BUY";
         }      
      if(HA_trend_count ==  HA_Lookback && HA_Open > HA_Close)
         {
            HA_crit = "SELL";
         }   
   //---Stochastic Criteria------------------------------------------------------------------------------------ 
      
      Stoch = iStochastic(NULL,0,Stoch_k_period,Stoch_d_period,Stoch_slowing,MODE_SMA,0,MODE_SIGNAL,0);
      
      if(Stoch < Stoch_oSold)
         {
            Stoch_crit = "BUY";
         }   
      if(Stoch > Stoch_oBought)
         {
            Stoch_crit = "SELL";
         }
   //---Debug/Print---------------------------------------------------------------------------------------------   
   
   if(Debug_Print == true)
      {
      if(Print_All_Lines == true) // Print per tick  
            Print("HA_crit = " + HA_crit + " SMA_crit = " + SMA_crit + " Stoch_crit = " + Stoch_crit);   // debug  
       else                     // Print only if criteria met
         if(SMA_crit == "BUY" && HA_crit == "BUY" && Stoch_crit == "BUY") 
            {
               Print("BUY SIGNAL DETECTED!");
               Print("HA_crit = " + HA_crit + ", SMA_crit = " + SMA_crit + ", Stoch_crit = " + Stoch_crit);
            }
         if(SMA_crit == "SELL" && HA_crit == "SELL" && Stoch_crit == "SELL") 
            {
               Print("SELL SIGNAL DETECTED!");
               Print("HA_crit = " + HA_crit + ", SMA_crit = " + SMA_crit + ", Stoch_crit = " + Stoch_crit);
            }
      }    
          
      
    //--Trading Criteria-----------------------------------------------------------------------------------------
      if(SMA_crit == "BUY" && HA_crit == "BUY" && Stoch_crit == "BUY") 
         {
            return(BUY_OPEN);
         } 
      else if(SMA_crit == "SELL" && HA_crit == "SELL" && Stoch_crit == "SELL") 
         {
            return(SELL_OPEN);
         }
      else
            return(HOLD);      
   }
   
//-------------------------------------------------------------- 11 --  

