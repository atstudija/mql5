//+------------------------------------------------------------------+
//|                                                      h_TS_BW.mqh |
//|                                                         olyakish |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "olyakish"
#property link      "http://www.mql5.com"



#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include<Trade\HistoryOrderInfo.mqh>
// ïåðå÷èñëÿåìûé ñïèñîê âàðèàíòîâ òðåéëèíã ñòîïà ïî àëëèãàòîðó
enum type_support_position
  {
   Not_used=-1,               // Ñîïðîâîæäåíèå ñòîïîâîé öåíû ó ïîçèöèè íå èñïîëüçóåòñÿ
   Trailing_On_Lips=0,        // Òðåéëèã ñòîï ïî ïî ËèíèèÃóá
   Trailing_On_Teeth=1,       // Òðåéëèã ñòîï ïî Ëèíèè Çóáîâ
   Trailing_On_Jaws=2,        // Òðåéëèã ñòîï ïî Ëèíèè ×åëþñòåé
   Close_On_Lips=3,           // Çàêðûòèå ïîçèöèè åñëè öåíà çàêðûëàñü çà Ãóáèìè Àëëèãàòîðà
   Close_On_Teeth=4,          // Çàêðûòèå ïîçèöèè åñëè öåíà çàêðûëàñü çà Çóáàìè Àëëèãàòîðà
   Close_On_Jaw=5,            // Çàêðûòèå ïîçèöèè åñëè öåíà çàêðûëàñü çà ×åëþñòüþ Àëëèãàòîðà
   Close_Out_Alligator=6      // Çàêðûòèå çà ïðîòèâîïîëîæíîé ãðàíèöåé Àëëèãàòîðà 
  };
  
struct            s_input_parametrs // ñòðóêðóðà íàñòðîå÷íûõ ïàðàìåòðîâ 
     {
      double            lot;                // ëîò äëÿ òîðãîâëè (âõîäÿùèé)
      type_support_position support_position; // Ñîïðîâîæäåíèå ñòîïîâîé öåíû ó ïîçèöèè
      int               alligator_jaw_period;//Àëëèãàòîð: ïåðèîä ëèíèè ÷åëþñòåé
      int               alligator_jaw_shift;//Àëëèãàòîð: ñäâèã ëèíèè ÷åëþñòåé
      int               alligator_teeth_period;//Àëëèãàòîð: ïåðèîä ëèíèè çóáîâ
      int               alligator_teeth_shift;//Àëëèãàòîð: ñäâèã ëèíèè çóáîâ
      int               alligator_lips_period;//Àëëèãàòîð: ïåðèîä ëèíèè ãóá
      int               alligator_lips_shift;//Àëëèãàòîð: ñäâèã ëèíèè ãóá
      int               max_4_dimension_zone;  // Ìàêñèìàëüíîå êîëè÷åñòâî ïîäðÿä áàðîâ çîí îäíîãî öâåòà      
      bool              add_1_dimension;  // Ðàçðåøèòü äîëèâêó ïî ôðàêòàëàì
      bool              add_2_dimension_bludce;  // Ðàçðåøèòü äîëèâêó ïî ñèãíàëó "áëþäöå (ÀÎ)"
      bool              add_2_dimension_cross_zero;  // Ðàçðåøèòü äîëèâêó ïî ñèãíàëó "ïåðåñå÷åíèå íóëåâîé ëèíèè (ÀÎ)"
      bool              add_3_dimension_use_2_bars;  // Ðàçðåøèòü äîëèâêó ïî ñèãíàëó "ïîêóïêà âûøå 0, ïðîäàæà íèæå 0" (ÀÑ 2 áàðà)
      bool              add_3_dimension_use_3_bars;  // Ðàçðåøèòü äîëèâêó ïî ñèãíàëó "ïîêóïêà íèæå 0, ïðîäàæà âûøå 0" (ÀÑ 3 áàðà)
      bool              add_4_dimension_zone;  // Ðàçðåøèòü äîëèâêó ïî ñèãíàëàì îò êðàñíîé èëè çåëåíîé çîí
      bool              add_5_dimension;       // Ðàçðåøèòü äîëèâêó ïî ñèãíàëàì îò ëèíèè áàëàíñà
      bool              trall_4_dimension;  // Ðàçðåøèòü òðàëë ïî 5 ïîäðÿä áàðàì çîí îäíîãî öâåòà
      bool              agress_trade_mm;  // Àãðåññèâíûé ñòèëü äîëèâàíèÿ â îòêðûòóþ ïîçèöèþ
     };  
//+------------------------------------------------------------------+
//|     Îïèñàíèå êëàññà   C_TS_BW                                    |
//+------------------------------------------------------------------+

class C_TS_BW
  {
private:
   datetime          time[1];                                  // âðåìÿ ïðè çàïðîñå 
   datetime          last_time[1];                             // âðåìÿ ïðåäûäóùåãî çàïðîñà (íóæíû äëÿ îïðåäåëåíèÿ ïîÿâëåíèÿ íîâîãî áàðà)
   int               h_alligator,h_fractals,h_ao,h_ac;              //Õåíäëû  
   string            m_Symbol;                                      // ñèìâîë íà êîòîðîì òîðãóåì
   ENUM_TIMEFRAMES   m_Period;                                      // ïåðèîä ñèìâîëà íà êîòîðîì òîðãóåì 
   CTrade            exp_trade;                                     //  òîðãîâûå ìåòîäû èç ñòàíäàðòíîé áèáëèîòåêè
   CSymbolInfo       s_info;                                        // ìåòîäû äîñòóïà ê èíôîðìàöèè ïî ñèìâîëó
   CPositionInfo     pos_info;                                      // ìåòîäû ïîëó÷åíèÿ èíôîðìàöèè ïî òîðãîâîé ïîçèöèè
   CHistoryOrderInfo h_info;                                        // ìåòîäû äîñòóïà ê èñòîðèè îðäåðîâ
   bool              FindSignal_1_dimension(int type,double&price_out[],datetime &time_out[]);  // ïîèñê ñèãíàëîâ îò ïåðâîãî èçìåðåíèÿ
   bool              FindSignal_2_dimension(int type,int sub_type,double&price_out[],datetime &time_out[]);  // ïîèñê ñèãíàëîâ îò âòîðîãî èçìåðåíèÿ
   bool              FindSignal_3_dimension(int type,int sub_type,double&price_out[],datetime &time_out[]);  // ïîèñê ñèãíàëîâ îò òðåòüåãî èçìåðåíèÿ 
   bool              FindSignal_4_dimension(int type,int sub_type,double&price_out[],datetime &time_out[]);  // ïîèñê ñèãíàëîâ îò ÷åòâåðòîãî èçìåðåíèÿ 
   bool              FindSignal_5_dimension(int type,int sub_type,double&price_out[],datetime &time_out[]);  // ïîèñê ñèãíàëîâ îò ïÿòîãî èçìåðåíèÿ
   bool              CheckForTradeSignal(int dimension,int type,int sub_type,double&price_out[],datetime &time_out[]);  // ïðîâåðêà ñèãíàëîâ íà âîçìîæíîñòü òîðãîâëè â òåêóùåé ìîìåíò
   bool              SendOrder(ENUM_ORDER_TYPE type,double&price_out[],datetime &time_out[],string comment); // îòïðàâêà îðäåðà íà ñåðâåð
   bool              CopyIndValue(int type,int countValue);
   ulong             CalcMagic(ulong  &magic);           // âû÷èñëåíèå íåîáõîäèìîãî ìàãèêà äëÿ íîâîãî îðäåðà   
   double            High[],Low[],Close[],AO_color[],AO_value[],AC_color[],AC_value[];      // ìàññèâû äëÿ õðàíåíèÿ çíà÷åíèé 
   double            lips[],teeth[],jaw[];                       // ìàññèâû äëÿ õðàíåíèÿ çíà÷åíèé îò Àëëèãàòîðà 
   double            Lot; // ëîò äëÿ òîðãîâëè
   double            StopLoss;            // Öåíà äëÿ óñòàíîâêè ñòîïëîññ
   ulong             Magic;  // ìàãèê   

   struct l_signals         //// ñòðóêòóðà ñèãíàëîâ
     {
      double            fractal_up[1];  // öåíà ïîñëåäíåãî àêòóàëüíîãî ôðàêòàëà íà ïîêóïêó (èíäèêàòîð Ôðàêòàëû)
      double            fractal_dn[1];  // öåíà ïîñëåäíåãî àêòóàëüíîãî ôðàêòàëà íà ïðîäàæó (èíäèêàòîð Ôðàêòàëû)
      double            bludce_up[1];   // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "áëþäöå" íà  ïîêóïêó (èíäèêàòîð ÀÎ)
      double            bludce_dn[1];   // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "áëþäöå" íà  ïðîäàæó (èíäèêàòîð ÀÎ)
      double            cross_zero_up[1]; // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïåðåñå÷åíèå íóëåâîé ëèíèè" íà  ïîêóïêó (èíäèêàòîð ÀÎ)
      double            cross_zero_dn[1]; // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïåðåñå÷åíèå íóëåâîé ëèíèè" íà  ïðîäàæó (èíäèêàòîð ÀÎ)
      double            ac_2_bars_up[1];  // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïî äâóì ïîäðÿä çåëåíûì áàðàì îò ÀÑ" íà  ïîêóïêó (èíäèêàòîð ÀÑ)
      double            ac_2_bars_dn[1];  // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïî äâóì ïîäðÿä êðàñíûì áàðàì îò ÀÑ" íà  ïðîäàæó (èíäèêàòîð ÀÑ)
      double            ac_3_bars_up[1];  // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïî òðåì ïîäðÿä çåëåíûì áàðàì îò ÀÑ" íà  ïîêóïêó (èíäèêàòîð ÀÑ)
      double            ac_3_bars_dn[1];  // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïî òðåì ïîäðÿä êðàñíûì áàðàì îò ÀÑ" íà  ïðîäàæó (èíäèêàòîð ÀÑ)
      double            zone_up[1];       // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "çåëåíàÿ çîíà" íà  ïîêóïêó (èíäèêàòîðû ÀÎ , ÀÑ è öåíà Close)
      double            zone_dn[1];       // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "êðàñíàÿ çîíà" íà  ïðîäàæó (èíäèêàòîðû ÀÎ , ÀÑ è öåíà Close)
      double            zone_5_trall_green[1]; // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïåðåíîñ ñòîï ïðèêàçà ïî ïÿòè ïîäðÿä çåëåíûì çîíàì" äëÿ ïîçèöèè íà ïîêóïêó (èíäèêàòîðû ÀÎ è  ÀÑ)
      double            zone_5_trall_red[1];   // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïåðåíîñ ñòîï ïðèêàçà ïî ïÿòè ïîäðÿä êðàñíûì çîíàì" äëÿ ïîçèöèè íà ïðîäàæó (èíäèêàòîðû ÀÎ è  ÀÑ)
      double            five_dimension_2_bars_up[1]; // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïîêóïêà âûøå ëèíèè áàëàíñà (â çåëåíîé çîíå)"  íà  ïîêóïêó (èíäèêàòîð Àëëèãàòîð è öåíà High)
      double            five_dimension_3_bars_up[1]; // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïîêóïêà âûøå ëèíèè áàëàíñà (â êðàñíîé çîíå)"  íà  ïîêóïêó (èíäèêàòîð Àëëèãàòîð è öåíà High)
      double            five_dimension_2_bars_dn[1]; // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïðîäàæà íèæå ëèíèè áàëàíñà (â êðàñíîé çîíå)"  íà  ïðîäàæó (èíäèêàòîð Àëëèãàòîð è öåíà Low)
      double            five_dimension_3_bars_dn[1]; // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïðîäàæà íèæå ëèíèè áàëàíñà (â çåëåíîé çîíå)"  íà  ïðîäàæó (èíäèêàòîð Àëëèãàòîð è öåíà Low)
      bool              alligator_trend[2];          // èäåíòèôèêàöèÿ òðåíäà ïî àëëèãàòðó íà íóëåâîì áàðå

      datetime          fractal_up_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ôðàêòàëà íà ïîêóïêó (èíäèêàòîð Ôðàêòàëû)
      datetime          fractal_dn_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ôðàêòàëà íà ïðîäàæó (èíäèêàòîð Ôðàêòàëû)
      datetime          bludce_up_time[1];  // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "áëþäöå" íà  ïîêóïêó (èíäèêàòîð ÀÎ)
      datetime          bludce_dn_time[1];  // öåíà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "áëþäöå" íà  ïðîäàæó (èíäèêàòîð ÀÎ)
      datetime          cross_zero_up_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïåðåñå÷åíèå íóëåâîé ëèíèè" íà  ïîêóïêó (èíäèêàòîð ÀÎ)
      datetime          cross_zero_dn_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïåðåñå÷åíèå íóëåâîé ëèíèè" íà  ïðîäàæó (èíäèêàòîð ÀÎ)
      datetime          ac_2_bars_up_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïî äâóì ïîäðÿä çåëåíûì áàðàì îò ÀÑ" íà  ïîêóïêó (èíäèêàòîð ÀÑ)
      datetime          ac_2_bars_dn_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïî äâóì ïîäðÿä êðàñíûì áàðàì îò ÀÑ" íà  ïðîäàæó (èíäèêàòîð ÀÑ)
      datetime          ac_3_bars_up_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïî òðåì ïîäðÿä çåëåíûì áàðàì îò ÀÑ" íà  ïîêóïêó (èíäèêàòîð ÀÑ)
      datetime          ac_3_bars_dn_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïî òðåì ïîäðÿä êðàñíûì áàðàì îò ÀÑ" íà  ïðîäàæó (èíäèêàòîð ÀÑ)
      datetime          zone_up_time[1];      // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "çåëåíàÿ çîíà" íà  ïîêóïêó (èíäèêàòîðû ÀÎ , ÀÑ è öåíà Close)
      datetime          zone_dn_time[1];      // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "êðàñíàÿ çîíà" íà  ïðîäàæó (èíäèêàòîðû ÀÎ , ÀÑ è öåíà Close)
      datetime          five_dimension_2_bars_up_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïåðåíîñ ñòîï ïðèêàçà ïî ïÿòè ïîäðÿä çåëåíûì çîíàì" äëÿ ïîçèöèè íà ïîêóïêó (èíäèêàòîðû ÀÎ è  ÀÑ)
      datetime          five_dimension_3_bars_up_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïîêóïêà âûøå ëèíèè áàëàíñà (â êðàñíîé çîíå)"  íà  ïîêóïêó (èíäèêàòîð Àëëèãàòîð è öåíà High)
      datetime          five_dimension_2_bars_dn_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïðîäàæà íèæå ëèíèè áàëàíñà (â êðàñíîé çîíå)"  íà  ïðîäàæó (èíäèêàòîð Àëëèãàòîð è öåíà Low)
      datetime          five_dimension_3_bars_dn_time[1]; // âðåìÿ áàðà ïîñëåäíåãî àêòóàëüíîãî ñèãíàëà "ïðîäàæà íèæå ëèíèè áàëàíñà (â çåëåíîé çîíå)"  íà  ïðîäàæó (èíäèêàòîð Àëëèãàòîð è öåíà Low)
      void              l_signals_clear(ENUM_POSITION_TYPE type) // çà÷èñòêà ñèãíàëîâ â çàâèñèìîñòè îò íàïðàâëåíèÿ
        {
         alligator_trend[0]=false;
         alligator_trend[1]=false;
         if(type==POSITION_TYPE_BUY)
           {
            fractal_up[0]=-1;
            bludce_up[0]=-1;
            cross_zero_up[0]=-1;
            ac_2_bars_up[0]=-1;
            ac_3_bars_up[0]=-1;
            zone_up[0]=-1;
            zone_5_trall_green[0]=-1;
            five_dimension_2_bars_up[0]=-1;
            five_dimension_3_bars_up[0]=-1;

            fractal_up_time[0]=-1;
            bludce_up_time[0]=-1;
            cross_zero_up_time[0]=-1;
            ac_2_bars_up_time[0]=-1;
            ac_3_bars_up_time[0]=-1;
            zone_up_time[0]=-1;
            five_dimension_2_bars_up_time[0]=-1;
            five_dimension_3_bars_up_time[0]=-1;
           }
         if(type==POSITION_TYPE_SELL)
           {
            fractal_dn[0]=-1;
            bludce_dn[0]=-1;
            cross_zero_dn[0]=-1;
            ac_2_bars_dn[0]=-1;
            ac_3_bars_dn[0]=-1;
            zone_dn[0]=-1;
            zone_5_trall_red[0]=-1;
            five_dimension_2_bars_dn[0]=-1;
            five_dimension_3_bars_dn[0]=-1;

            fractal_dn_time[0]=-1;
            bludce_dn_time[0]=-1;
            cross_zero_dn_time[0]=-1;
            ac_2_bars_dn_time[0]=-1;
            ac_3_bars_dn_time[0]=-1;
            zone_dn_time[0]=-1;
            five_dimension_2_bars_dn_time[0]=-1;
            five_dimension_3_bars_dn_time[0]=-1;
           }
        }
     };
   l_signals         last_signals;
   // ñòðóêòóðà âðåìåí ïîñëåäíèõ ñðàáîòàííûõ ñèãíàëîâ
   struct l_trade
     {
      datetime          fractal_up;
      datetime          fractal_dn;
      datetime          ao_blydce;
      datetime          ao_cross_zero;
      datetime          ac_2_bars;
      datetime          ac_3_bars;
      datetime          zone;
      datetime          five_dimension;
     };
   l_trade           last_trade;

   
   s_input_parametrs inp_param;        // âíóòðåííÿÿ ñòðóêòóðà ïðèíÿòûõ íàñòðîåê

public:
   void              C_TS_BW(); // êîíñòðóêòîð

   s_input_parametrs inp_param_tmp;    // ïðèåìíàÿ ñòðóêòóðà íàñòðîåê (ïîëó÷àåò ïî ññûëêå ïðè èíèöèàëèçàöèè êëàññà)

   struct s_actual_action
     {
      bool              fractal_open_buy;
      bool              fractal_add_buy;
      bool              fractal_revers_buy_to_sell;
      bool              fractal_open_sell;
      bool              fractal_add_sell;
      bool              fractal_revers_sell_to_buy;
      bool              ao_bludce_buy;
      bool              ao_bludce_sell;
      bool              ao_cross_zero_buy;
      bool              ao_cross_zero_sell;
      bool              ac_2_bar_buy;
      bool              ac_2_bar_sell;
      bool              ac_3_bar_buy;
      bool              ac_3_bar_sell;
      bool              zone_buy;
      bool              zone_sell;
      bool              line_balance_2_bar_buy;
      bool              line_balance_2_bar_sell;
      bool              line_balance_3_bar_buy;
      bool              line_balance_3_bar_sell;
      bool              position_close;
      void              init()
        {
         fractal_open_buy=false;
         fractal_add_buy=false;
         fractal_revers_buy_to_sell=false;
         fractal_open_sell=false;
         fractal_add_sell=false;
         fractal_revers_sell_to_buy=false;
         ao_bludce_buy=false;
         ao_bludce_sell=false;
         ao_cross_zero_buy=false;
         ao_cross_zero_sell=false;
         ac_2_bar_buy=false;
         ac_2_bar_sell=false;
         ac_2_bar_buy=false;
         ac_3_bar_sell=false;
         zone_buy=false;
         zone_sell=false;
         line_balance_2_bar_buy=false;
         line_balance_2_bar_sell=false;
         line_balance_3_bar_buy=false;
         line_balance_3_bar_sell=false;
         position_close=false;
        }
     };
   s_actual_action   actual_action;
   bool              Init(string Symbol_for_trade,ENUM_TIMEFRAMES Period_for_trade,s_input_parametrs  &inp_param_tmp); // èíèöèàëèçàöèÿ êëàññà
   bool              NewBar();// ïðîâåðêà íà íîâûé áàð íà òåêóùåì ñèìâîëå\òàéìôðåéìå
   void              CheckSignal();  // ïîèñê ñèãíàëîâ
   void              CheckActionOnTick();  // ñáîð æåëàåìûõ äåéñòâèé íà òåêóùåé òèê
   void              TrailingStop();  // ïîäòÿãèâàíèå ñòîïà
   void              TradeActualSignals();//Òîðãîâëÿ Ïî Àêòóàëüíûì Ñèãíàëàì()
   void              SetStopLoss(double  &stoploss);  // ïðèåì âíåøíåãî ñòîïà

                                                      // Ðàñ÷åò ëîòà (åñëè !external òî ðàñ÷åò èäåò âíóòðåííèìè ñèëàìè êëàññà èíà÷å òîðãóåì ext_lot)
   void              CalcLot(bool external,double ext_lot,int type);

  };
//+------------------------------------------------------------------+ 

C_TS_BW::C_TS_BW(void)
  {
  }
//+------------------------------------------------------------------+
//| Èíèöèàëèçàöèÿ êëàññà                                             +
//|       Symbol_for_trade - Ñèìâîë äëÿ òîðãîâëè                     +
//|       Period_for_trade- Ïåðèîä ãðàôèêà äëÿ òîðãîâëè              +
//|  Ïðè íåóäà÷íîé èíèöèàëèçàöèè âîçâðàùàåò false - íåîáõîäèìî ïîâòîðíàÿ ïåðåèíèöèàëèçàöèÿ
//+------------------------------------------------------------------+
bool C_TS_BW::Init(string Symbol_for_trade,ENUM_TIMEFRAMES Period_for_trade,s_input_parametrs  &inp_param_tmp)
  {
   inp_param=inp_param_tmp;
   time[0]=-1;                                  // âðåìÿ ïðè çàïðîñå 
   last_time[0]=-2;
   m_Symbol=Symbol_for_trade;
   m_Period=Period_for_trade;
   Lot=inp_param.lot;
   StopLoss=-1;
   Magic=-1;
// ðàñïðåäåëåíèå õåíäëîâ
   h_alligator=iAlligator(m_Symbol,m_Period,inp_param.alligator_jaw_period,0,inp_param.alligator_teeth_period,0,inp_param.alligator_lips_period,0,MODE_SMMA,PRICE_MEDIAN);
   if(h_alligator==INVALID_HANDLE){return(false);}
   h_fractals=iFractals(m_Symbol,m_Period);
   if(h_fractals==INVALID_HANDLE){return(false);}
   h_ao=iAO(m_Symbol,m_Period);
   if(h_ao==INVALID_HANDLE){return(false);}
   h_ac=iAC(m_Symbol,m_Period);
   if(h_ac==INVALID_HANDLE){return(false);}
// èíäåêñàöèÿ â ìàññèâàõ êàê òàéìñåðèÿ 
   ArraySetAsSeries(AO_color,true);
   ArraySetAsSeries(AO_value,true);
   ArraySetAsSeries(AC_color,true);
   ArraySetAsSeries(AC_value,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(lips,true);
   ArraySetAsSeries(teeth,true);
   ArraySetAsSeries(jaw,true);
// èíèöèàëèçàöèÿ íàñëåäóåìûõ êëàññîâ
   s_info.Name(m_Symbol);       // Ñ êàêèì èíñòðóìåíòîì ðàáîòàåì
   s_info.Refresh();            // ïîëó÷àåì îêðóæåíèå ïî ñèìâîëó
   return(true);
  }
//+------------------------------------------------------------------+
//|  Ïîèñê íîâîãî áàðà (Åñëè íîâûé òî true èíà÷å false               |
//+------------------------------------------------------------------+
bool C_TS_BW::NewBar(void)
  {
   int copy=-1;
   copy=CopyTime(m_Symbol,m_Period,0,1,time);
   if(copy>0 && time[0]>last_time[0])
     {
      last_time[0]=time[0];
      return(true);
     }
   else
     {return(false);}
  }
//+------------------------------------------------------------------+
//    ïîèñê ñèãíàëîâ îò 5-è èçìåðåíèé 
//+------------------------------------------------------------------+
void C_TS_BW::CheckSignal(void)
  {
   CopyClose(m_Symbol,m_Period,0,3,Close);
   datetime tmp_timer[1];
   last_signals.alligator_trend[0]=false;
   last_signals.alligator_trend[1]=false;
   CopyIndValue(0,2);  // äîñòàåì àëëèãàòîð íà íóëåâîì áàðå
   CopyIndValue(2,10);  // äîñòàåì ÀÎ
   CopyIndValue(3,10);  // äîñòàåì ÀÑ  



   bool select_pos=pos_info.Select(m_Symbol);
   if(select_pos)
     {
      switch(inp_param.support_position)
        {
         case 3:        //Close_On_Lips=3,           // Çàêðûòèå ïîçèöèè åñëè öåíà çàêðûëàñü çà Ãóáèìè Àëëèãàòîðà
           {
            if(((ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_BUY && Close[1]<lips[1]) ||
               ((ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_SELL && Close[1]>lips[1]))
              {actual_action.position_close=true;}
            break;
           }
         case 4:           //Close_On_Teeth=4,          // Çàêðûòèå ïîçèöèè åñëè öåíà çàêðûëàñü çà Çóáàìè Àëëèãàòîðà
           {
            if(((ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_BUY && Close[1]<teeth[1]) ||
               ((ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_SELL && Close[1]>teeth[1]))
              {actual_action.position_close=true;}
            break;
           }
         case 5:           //Close_On_Jaw=5             // Çàêðûòèå ïîçèöèè åñëè öåíà çàêðûëàñü çà ×åëþñòüþ Àëëèãàòîðà     
           {
            if(((ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_BUY && Close[1]<jaw[1]) ||
               ((ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_SELL && Close[1]>jaw[1]))
              {actual_action.position_close=true;}
            break;
           }
         case 6:           //Close_Out_Alligator=6            
           {
            if(((ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_BUY && Close[1]<MathMin(jaw[1],MathMin(lips[1],teeth[1]))) ||
               ((ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_SELL && Close[1]>MathMax(jaw[1],MathMax(lips[1],teeth[1]))))
              {actual_action.position_close=true;}
            break;
           }           
        }
     }

   last_signals.l_signals_clear(POSITION_TYPE_BUY);
   last_signals.l_signals_clear(POSITION_TYPE_SELL);
//--- òðåíä ïî àëëèãàòîðó 
   if(lips[0]>teeth[0] && teeth[0]>jaw[0]){last_signals.alligator_trend[0]=true;}
   if(lips[0]<teeth[0] && teeth[0]<jaw[0]){last_signals.alligator_trend[1]=true;}   
   FindSignal_1_dimension(0,last_signals.fractal_up,last_signals.fractal_up_time);  // èùèì àêòóàëüíûé ôðàêòàë íà ïîêóïêó
   FindSignal_1_dimension(1,last_signals.fractal_dn,last_signals.fractal_dn_time);  // èùèì àêòóàëüíûé ôðàêòàë íà ïðîäàæó
   if(select_pos && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_BUY && last_signals.alligator_trend[0])
     {
      FindSignal_2_dimension(0,0,last_signals.cross_zero_up,last_signals.cross_zero_up_time);  //  ÀÎ Ïåðåñå÷åíèå íóëåâîé ëèíèè (íà ïîêóïêó)
      FindSignal_2_dimension(0,1,last_signals.bludce_up,last_signals.bludce_up_time);  //  ÀÎ Áëþäöå (íà ïîêóïêó)
      FindSignal_3_dimension(0,0,last_signals.ac_2_bars_up,last_signals.ac_2_bars_up_time);  //  AC (íà ïîêóïêó) ïî äâóì çåëåíûì áàðàì 
      FindSignal_3_dimension(0,1,last_signals.ac_3_bars_up,last_signals.ac_3_bars_up_time);  //  AC (íà ïîêóïêó) ïî òðåì çåëåíûì áàðàì 
      FindSignal_4_dimension(0,0,last_signals.zone_up,last_signals.zone_up_time);            //ïîèñê  ñèãíàëà íà ïîêóïêó îò çåëåíîé çîíû
      FindSignal_4_dimension(0,1,last_signals.zone_5_trall_green,tmp_timer);            //ïîèñê  öåíû äëÿ ïåðåíîñà ñòîïà ïî ïÿòèáàðîâîé çåëåíîé çîíå 
      FindSignal_4_dimension(0,2,last_signals.zone_up,last_signals.zone_up_time);            //îãðàíè÷åíèÿ íà âõîä ïî ñèãíàëàì îò çåëåíîé çîíû ïî êîëè÷åñòâó ïîäðÿä çåëåíûõ çîí
      FindSignal_5_dimension(0,0,last_signals.five_dimension_2_bars_up,last_signals.five_dimension_2_bars_up_time);            //ïîèñê  ñèãíàëà íà ïîêóïêó îò ëèíèè áàëàíñà (2 áàðà)
      FindSignal_5_dimension(0,1,last_signals.five_dimension_3_bars_up,last_signals.five_dimension_3_bars_up_time);            //ïîèñê  ñèãíàëà íà ïîêóïêó îò ëèíèè áàëàíñà (3 áàðà)      
     }
   if(select_pos && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_SELL && last_signals.alligator_trend[1])
     {
      FindSignal_2_dimension(1,0,last_signals.cross_zero_dn,last_signals.cross_zero_dn_time);  //  ÀÎ Ïåðåñå÷åíèå íóëåâîé ëèíèè (íà ïðîäàæó)
      FindSignal_2_dimension(1,1,last_signals.bludce_dn,last_signals.bludce_dn_time);  //  ÀÎ Áëþäöå (íà ïðîäàæó)
      FindSignal_3_dimension(1,0,last_signals.ac_2_bars_dn,last_signals.ac_2_bars_dn_time);  //  AC (íà ïðîäàæó) ïî äâóì êðàñíûì áàðàì 
      FindSignal_3_dimension(1,1,last_signals.ac_3_bars_dn,last_signals.ac_3_bars_dn_time);  //  AC (íà ïðîäàæó) ïî òðåì êðàñíûì áàðàì 
      FindSignal_4_dimension(1,0,last_signals.zone_dn,last_signals.zone_dn_time);            //ïîèñê  ñèãíàëà íà ïðîäàæó îò êðàñíîé çîíû
      FindSignal_4_dimension(1,1,last_signals.zone_5_trall_red,tmp_timer);            //ïîèñê  öåíû äëÿ ïåðåíîñà ñòîïà ïî ïÿòèáàðîâîé êðàñíîé çîíå       
      FindSignal_4_dimension(1,2,last_signals.zone_dn,last_signals.zone_dn_time);            //îãðàíè÷åíèÿ íà âõîä ïî ñèãíàëàì îò êðàñíîé  çîíû ïî êîëè÷åñòâó ïîäðÿä êðàñíûõ çîí
      FindSignal_5_dimension(1,0,last_signals.five_dimension_2_bars_dn,last_signals.five_dimension_2_bars_dn_time);            //ïîèñê  ñèãíàëà íà ïðîäàæó îò ëèíèè áàëàíñà (2 áàðà)   
      FindSignal_5_dimension(1,1,last_signals.five_dimension_3_bars_dn,last_signals.five_dimension_3_bars_dn_time);            //ïîèñê  ñèãíàëà íà ïðîäàæó îò ëèíèè áàëàíñà (3 áàðà)
     }
  }
//+------------------------------------------------------------------+
//    ñîïðîâîæäåíèå ïîçèöèè (Òðàéëèíã Ñòîï)
//+------------------------------------------------------------------+
void C_TS_BW::TrailingStop(void)
  {
   bool select=pos_info.Select(m_Symbol);
   if(select && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_BUY
      && last_signals.zone_5_trall_green[0]>0 && inp_param.trall_4_dimension)
     {StopLoss=last_signals.zone_5_trall_green[0];}
   if(select && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_SELL
      && last_signals.zone_5_trall_red[0]>0 && inp_param.trall_4_dimension)
     {StopLoss=last_signals.zone_5_trall_red[0];}
   if(select && StopLoss<0)
     {
      switch(inp_param.support_position)
        {
         case -1:       //Not_used=-1,               // Ñîïðîâîæäåíèå ñòîïîâîé öåíû ó ïîçèöèè íå èñïîëüçóåòñÿ
           {break;}
         case 0:        //Trailing_On_Lips=0,        // Òðåéëèã ñòîï ïî ïî ËèíèèÃóá
           {StopLoss=lips[0];break;}
         case 1:        //Trailing_On_Teeth=1,       // Òðåéëèã ñòîï ïî Ëèíèè Çóáîâ
           {StopLoss=teeth[0];break;}
         case 2:       //Trailing_On_Jaws=2,        // Òðåéëèã ñòîï ïî Ëèíèè ×åëþñòåé
           {StopLoss=jaw[0];break;}
        }
     }

//---
   if(StopLoss>0 && 
      ((pos_info.StopLoss()+s_info.Point()<StopLoss && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_BUY && StopLoss<Close[0]-(s_info.StopsLevel()+s_info.Spread()*2)*s_info.Point()) || // ïðîâåðêà íà ìèíèìàëüíîå èçìåíåíèå ñòîïà
      (((pos_info.StopLoss()-s_info.Point()>StopLoss && pos_info.StopLoss()>0) || (pos_info.StopLoss()<s_info.Point()*5)) && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_SELL && StopLoss>Close[0]+(s_info.StopsLevel()+s_info.Spread()*2)*s_info.Point()))) // ïðîâåðêà íà ìèíèìàëüíîå èçìåíåíèå ñòîïà
     {
      //MathSrand((int)TimeCurrent());
      //string nameojb="stop"+(string) MathRand();
      //ResetLastError();
      //datetime t1[1];
      //CopyTime(m_Symbol,m_Period,0,1,t1);
      //bool draw=ObjectCreate(0,nameojb,OBJ_ARROW_STOP,0,t1[0],StopLoss);
      //Print(nameojb," ",(string)draw,GetLastError());

      if(exp_trade.PositionModify(m_Symbol,NormalizeDouble(StopLoss,s_info.Digits()),pos_info.TakeProfit()))
        {StopLoss=-1.0;}
     }

   StopLoss=-1.0;

  }
//+------------------------------------------------------------------+
//    Òîðãîâëÿ àêòóàëüíûõ ñèãíàëîâ
//+------------------------------------------------------------------+
void C_TS_BW::TradeActualSignals(void)
  {
   s_info.Refresh();            // ïîëó÷àåì îêðóæåíèå ïî ñèìâîëó
   if(actual_action.position_close)
     {
      if(exp_trade.PositionClose(m_Symbol,-1))
        {actual_action.position_close=false;}
     }
   if(actual_action.fractal_open_buy || actual_action.fractal_add_buy || actual_action.fractal_revers_sell_to_buy) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ôðàêòàëà
     {
      if(Lot<0 && actual_action.fractal_open_buy){last_signals.zone_5_trall_green[0]=-1;} // íåò îòêðûòûõ ïîçèöèé - âõîäèì ñòàðòîâûì ëîòîì
                                                                                          //if(Lot<0 && actual_action.fractal_add_buy){} // åñòü îòêðûòàÿ ïîçèöèÿ  Buy- âõîäèì äîëèâî÷íûì ëîòîì
      if(Lot<0 && actual_action.fractal_revers_sell_to_buy){last_signals.zone_5_trall_green[0]=-1;} // åñòü îòêðûòàÿ ïîçèöèÿ  Sell - âõîäèì ïåðåâîðîòíûì ëîòîì 
                                                                                                    //if(Lot>0)
        {
         last_trade.fractal_up=last_signals.fractal_up_time[0];
         if(SendOrder(ORDER_TYPE_BUY,last_signals.fractal_up,last_signals.fractal_up_time,"TC_BW_fr_"+TimeToString(last_signals.fractal_up_time[0])))
           {
            actual_action.fractal_open_buy=false;
            actual_action.fractal_add_buy=false;
            actual_action.fractal_revers_sell_to_buy=false;
            return;
           }
        }
     }
   if(actual_action.fractal_open_sell || actual_action.fractal_add_sell || actual_action.fractal_revers_buy_to_sell) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ôðàêòàëà
     {
      if(Lot<0 && actual_action.fractal_open_sell){last_signals.zone_5_trall_red[0]=-1;} // íåò îòêðûòûõ ïîçèöèé - âõîäèì ñòàðòîâûì ëîòîì
                                                                                         //if(Lot<0 && actual_action.fractal_add_sell){} // åñòü îòêðûòàÿ ïîçèöèÿ  Sell- âõîäèì äîëèâî÷íûì ëîòîì
      if(Lot<0 && actual_action.fractal_revers_buy_to_sell){last_signals.zone_5_trall_red[0]=-1;} // åñòü îòêðûòàÿ ïîçèöèÿ  Buy - âõîäèì ïåðåâîðîòíûì ëîòîì 
                                                                                                  //if(Lot>0)
        {
         last_trade.fractal_dn=last_signals.fractal_dn_time[0];
         if(SendOrder(ORDER_TYPE_SELL,last_signals.fractal_dn,last_signals.fractal_dn_time,"TC_BW_fr"+TimeToString(last_signals.fractal_dn_time[0])))
           {
            actual_action.fractal_open_sell=false;
            actual_action.fractal_add_sell=false;
            actual_action.fractal_revers_buy_to_sell=false;
            return;
           }
        }
     }
//---äîëèâêè îò 2-5 èçìåðåíèé ïîêóïêà
//---áëþäöå         
   if(actual_action.ao_bludce_buy) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ÀÎ "áëþäöå"
     {
      last_trade.ao_blydce=last_signals.bludce_up_time[0];
      if(SendOrder(ORDER_TYPE_BUY,last_signals.bludce_up,last_signals.bludce_up_time,"TC_BW_bl_"+TimeToString(last_signals.bludce_up_time[0])))
        {actual_action.ao_bludce_buy=false;return;}
     }
//--- ïåðåñå÷åíèå íóëåâîé ëèíèè          
   if(actual_action.ao_cross_zero_buy) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ÀÎ "ïåðåñå÷åíèå íóëåâîé ëèíèè"
     {
      last_trade.ao_cross_zero=last_signals.cross_zero_up_time[0];
      if(SendOrder(ORDER_TYPE_BUY,last_signals.cross_zero_up,last_signals.cross_zero_up_time,"TC_BW_cz_"+TimeToString(last_signals.cross_zero_up_time[0])))
        {actual_action.ao_cross_zero_buy=false;return;}
     }
//--- 2-õ áàðîâûé ñèãíàë íà ïîêóïêó îò ÀÑ
   if(actual_action.ac_2_bar_buy) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ÀC "äâà çåëåíûõ áàðà"
     {
      last_trade.ac_2_bars=last_signals.ac_2_bars_up_time[0];
      if(SendOrder(ORDER_TYPE_BUY,last_signals.ac_2_bars_up,last_signals.ac_2_bars_up_time,"TC_BW_2g_"+TimeToString(last_signals.ac_2_bars_up_time[0])))
        {actual_action.ac_2_bar_buy=false;return;}
     }
//--- 3-õ áàðîâûé ñèãíàë íà ïîêóïêó îò ÀÑ
   if(actual_action.ac_3_bar_buy) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ÀC "òðè çåëåíûõ áàðà"
     {
      last_trade.ac_3_bars=last_signals.ac_3_bars_up_time[0];
      if(SendOrder(ORDER_TYPE_BUY,last_signals.ac_3_bars_up,last_signals.ac_3_bars_up_time,"TC_BW_3g_"+TimeToString(last_signals.ac_3_bars_up_time[0])))
        {actual_action.ac_3_bar_buy=false;return;}
     }
//--- çåëåíàÿ çîíà
   if(actual_action.zone_buy) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò "çåëåíîé çîíû"
     {
      last_trade.zone=last_signals.zone_up_time[0];
      if(SendOrder(ORDER_TYPE_BUY,last_signals.zone_up,last_signals.zone_up_time,"TC_BW_z_"+TimeToString(last_signals.zone_up_time[0])))
        {actual_action.zone_buy=false;return;}
     }
//--- ëèíèÿ áàëàíñà 2-õ áàðîâûé ñèãíàë
   if(actual_action.line_balance_2_bar_buy) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ëèíèè áàíàíñà
     {
      last_trade.five_dimension=last_signals.five_dimension_2_bars_up_time[0];
      if(SendOrder(ORDER_TYPE_BUY,last_signals.five_dimension_2_bars_up,last_signals.five_dimension_2_bars_up_time,"BW_lb2_"+TimeToString(last_signals.five_dimension_2_bars_up_time[0])+DoubleToString(last_signals.five_dimension_2_bars_up[0],5)))
        { actual_action.line_balance_2_bar_buy=false;return;}
     }
//--- ëèíèÿ áàëàíñà 3-õ áàðîâûé ñèãíàë
   if(actual_action.line_balance_3_bar_buy) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ëèíèè áàíàíñà
     {
      last_trade.five_dimension=last_signals.five_dimension_3_bars_up_time[0];
      if(SendOrder(ORDER_TYPE_BUY,last_signals.five_dimension_3_bars_up,last_signals.five_dimension_3_bars_up_time,"BW_lb3_"+TimeToString(last_signals.five_dimension_3_bars_up_time[0])+DoubleToString(last_signals.five_dimension_3_bars_up[0],5)))
        {actual_action.line_balance_3_bar_buy=false;return;}
     }

//---
//---äîëèâêè â îòêðûòóþ ïîçèöèþ ïî íàïðàâëåíèþ ïðîäàæè
//---
   if(actual_action.ao_bludce_sell) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ÀÎ "áëþäöå"
     {
      last_trade.ao_blydce=last_signals.bludce_dn_time[0];
      if(SendOrder(ORDER_TYPE_SELL,last_signals.bludce_dn,last_signals.bludce_dn_time,"TC_BW_bl_"+TimeToString(last_signals.bludce_dn_time[0])))
        {actual_action.ao_bludce_sell=false;return;}
     }
   if(actual_action.ao_cross_zero_sell) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ÀÎ "ïåðåñå÷åíèå íóëåâîé ëèíèè"
     {
      last_trade.ao_cross_zero=last_signals.cross_zero_dn_time[0];
      if(SendOrder(ORDER_TYPE_SELL,last_signals.cross_zero_dn,last_signals.cross_zero_dn_time,"TC_BW_cz_"+TimeToString(last_signals.cross_zero_dn_time[0])))
        {actual_action.ao_cross_zero_sell=false;return;}
     }
//--- 2-õ áàðîâûé ñèãíàë íà ïðîäàæó îò ÀÑ
   if(actual_action.ac_2_bar_sell) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ÀC "äâà êðàñíûõ áàðà"
     {
      last_trade.ac_2_bars=last_signals.ac_2_bars_dn_time[0];
      if(SendOrder(ORDER_TYPE_SELL,last_signals.ac_2_bars_dn,last_signals.ac_2_bars_dn_time,"TC_BW_2g_"+TimeToString(last_signals.ac_2_bars_dn_time[0])))
        {actual_action.ac_2_bar_sell=false;return;}
     }
//--- 3-õ áàðîâûé ñèãíàë íà ïîêóïêó îò ÀÑ
   if(actual_action.ac_3_bar_sell) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ÀC "òðè êðàñíûõ áàðà"
     {
      last_trade.ac_3_bars=last_signals.ac_3_bars_dn_time[0];
      if(SendOrder(ORDER_TYPE_SELL,last_signals.ac_3_bars_dn,last_signals.ac_3_bars_dn_time,"TC_BW_3g_"+TimeToString(last_signals.ac_3_bars_dn_time[0])))
        {actual_action.ac_3_bar_sell=false;return;}
     }
//--- êðàñíàÿ çîíà
   if(actual_action.zone_sell) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò "êðàñíîé çîíû"
     {
      last_trade.zone=last_signals.zone_dn_time[0];
      if(SendOrder(ORDER_TYPE_SELL,last_signals.zone_dn,last_signals.zone_dn_time,"TC_BW_z_"+TimeToString(last_signals.zone_dn_time[0])))
        {actual_action.zone_sell=false;return;}
     }
//--- ëèíèÿ áàëàíñà 2-õ áàðîâûé ñèãíàë
   if(actual_action.line_balance_2_bar_sell) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ëèíèè áàíàíñà
     {
      last_trade.five_dimension=last_signals.five_dimension_2_bars_dn_time[0];
      if(SendOrder(ORDER_TYPE_SELL,last_signals.five_dimension_2_bars_dn,last_signals.five_dimension_2_bars_dn_time,"BW_lb2_"+TimeToString(last_signals.five_dimension_2_bars_dn_time[0])+DoubleToString(last_signals.five_dimension_2_bars_dn[0],5)))
        {actual_action.line_balance_2_bar_sell=false;return;}
     }
//--- ëèíèÿ áàëàíñà 3-õ áàðîâûé ñèãíàë
   if(actual_action.line_balance_3_bar_sell) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ëèíèè áàíàíñà
     {
      last_trade.five_dimension=last_signals.five_dimension_3_bars_dn_time[0];
      if(SendOrder(ORDER_TYPE_SELL,last_signals.five_dimension_3_bars_dn,last_signals.five_dimension_3_bars_dn_time,"BW_lb3_"+TimeToString(last_signals.five_dimension_3_bars_dn_time[0])+DoubleToString(last_signals.five_dimension_3_bars_dn[0],5)))
        {actual_action.line_balance_3_bar_sell=false;return;}
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//    Êîïèðîâàíèå çíà÷åíèé èíäèêàêòîðîâ â ìàññèâû äëÿ ïîèñêà ñèãíàëîâ
//  type - ÷òî òðåáóåì  (0- àëëèãàòîð, 2 - ÀÎ, 3 - ÀÑ  )
//  countValue -  êîëè÷åñòâî äàííûõ 
//+------------------------------------------------------------------+
bool C_TS_BW::CopyIndValue(int type,int countValue)
  {
   int copyCount=-1;
   switch(type)
     {
      case 0: // àëëèãàòîð
         copyCount=CopyBuffer(h_alligator,0,inp_param.alligator_jaw_shift,countValue,jaw); // ÷åëþñòü
         //copyCount=CopyBuffer(h_alligator,0,0,countValue,jaw); // ÷åëþñòü
         if(copyCount<1){break;}
         copyCount=CopyBuffer(h_alligator,1,inp_param.alligator_teeth_shift,countValue,teeth); // çóáû
         if(copyCount<1){break;}
         copyCount=CopyBuffer(h_alligator,2,inp_param.alligator_lips_shift,countValue,lips); // ãóáû
         if(copyCount<1){break;}
         break;
      case 2:     // AO
         copyCount=CopyBuffer(h_ao,0,0,countValue,AO_value);
         if(copyCount<1){break;}
         copyCount=CopyBuffer(h_ao,1,0,countValue,AO_color);
         if(copyCount<1){break;}
         break;
      case 3:     // AC
         copyCount=CopyBuffer(h_ac,0,0,countValue,AC_value);
         if(copyCount<1){break;}
         copyCount=CopyBuffer(h_ac,1,0,countValue,AC_color);
         if(copyCount<1){break;}
         break;
     }
   if(copyCount<1){return(false);}
   else{return(true);}

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  // ïîèñê ñèãíàëîâ îò ïåðâîãî èçìåðåíèÿ                          |
//+------------------------------------------------------------------+

bool C_TS_BW::FindSignal_1_dimension(int type,double &price_out[],datetime &time_out[])
  {
   int i,copyCount=-1;
   double tmp_buf[1];
   price_out[0]=-1;
   for(i=3;i<50;i++)
     {
      copyCount=CopyBuffer(h_fractals,type,i,1,tmp_buf);
      if(copyCount<1){return(false);}
      if(tmp_buf[0]!=EMPTY_VALUE && price_out[0]==-1)
        {
         price_out[0]=tmp_buf[0];
         CopyTime(m_Symbol,m_Period,i,1,time_out); // êîïèðóåì âðåìÿ íàéäåííîãî ôðàêòàëà 
        }
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    // ïîèñê ñèãíàëîâ îò âòîðîãî èçìåðåíèÿ                        |
//+------------------------------------------------------------------+
bool C_TS_BW::FindSignal_2_dimension(int type,int sub_type,double &price_out[],datetime &time_out[])
  {
   int copyCount=-1;
// ïîèñê ñèãíàëîâ îò ÀÎ
   if((AO_value[1]>0 && AO_value[2]<0 && type==0 && sub_type==0) || // ïåðåñå÷åíèå íóëåâîé ëèíèè ÀÎ ñíèçó ââåðõ
      (AO_color[1]==0 && AO_color[2]==1 && AO_value[2]>0 && type==0 && sub_type==1)) // áëþäöå âûøå íóëåâîé ëèíèè
     {
      CopyHigh(m_Symbol,m_Period,1,1,price_out);
      CopyTime(m_Symbol,m_Period,1,1,time_out);
     }
   if((AO_value[1]<0 && AO_value[2]>0 && type==1 && sub_type==0) || // ïåðåñå÷åíèå íóëåâîé ëèíèè ÀÎ câåðõó âíèç 
      (AO_color[1]==1 && AO_color[2]==0 && AO_value[2]<0 && type==1 && sub_type==1)) // áëþäöå íèæå íóëåâîé ëèíèè
     {
      CopyLow(m_Symbol,m_Period,1,1,price_out);
      CopyTime(m_Symbol,m_Period,1,1,time_out);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| ïîèñê ñèãíàëîâ îò  òðåòüåãî èçìåðåíèÿ                            |
//+------------------------------------------------------------------+
bool C_TS_BW::FindSignal_3_dimension(int type,int sub_type,double &price_out[],datetime &time_out[])
  {
   int copyCount=-1;
   if((AC_color[1]==0  &&  AC_value[1]>0  &&  AC_color[2]==0  &&  AC_color[3]==1  &&  type==0  &&  sub_type==0) || //(ïîêóïêà) ÀÑ ïî äâóì çåëåíûì áàðàì 
      (AC_color[1]==0 && AC_value[1]<0 && AC_color[2]==0 && AC_color[3]==0 && AC_color[4]==1 && type==0 && sub_type==1)) //(ïîêóïêà) ÀÑ ïî òðåì  çåëåíûì áàðàì (êîãäà òðåòèé çåëåíûé íèæå íóëÿ)
     {
      copyCount=CopyHigh(m_Symbol,m_Period,1,1,price_out);
      if(copyCount<1){return(false);}
      CopyTime(m_Symbol,m_Period,1,1,time_out);
     }
   if((AC_color[1]==1  &&  AC_value[1]<0  &&  AC_color[2]==1  &&  AC_color[3]==0  &&  type==1  &&  sub_type==0) || //(ïðîäàæà) ÀÑ ïî äâóì êðàñíûì áàðàì 
      (AC_color[1]==1 && AC_value[1]>0 && AC_color[2]==1 && AC_color[3]==1 && AC_color[4]==0 && type==1 && sub_type==1)) //(ïðîäàæà) ÀÑ ïî òðåì  êðàñíûì áàðàì (êîãäà òðåòèé êðàñíûé âûøå íóëÿ)
     {
      copyCount=CopyLow(m_Symbol,m_Period,1,1,price_out);
      if(copyCount<1){return(false);}
      CopyTime(m_Symbol,m_Period,1,1,time_out);

     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  ïîèñê cèãíàëîâ îò ÷åòâåðòîãî èçìåðåíèÿ                          |
//+------------------------------------------------------------------+
bool C_TS_BW::FindSignal_4_dimension(int type,int sub_type,double &price_out[],datetime &time_out[])
  {
   int copyCount=-1;
   bool find_green_zone=true,find_red_zone=true;
   bool limit_green_zone=true,limit_red_zone=true;
   double tmp_h[1],tmp_l[1]; // âðåìåííûå ìàññèâû äëÿ õàÿ è ëîó
   if(sub_type==0) // ïîèñê âõîäîâ ïî ñèãíàëàì îò çîí
     {
      copyCount=CopyClose(m_Symbol,m_Period,0,3,Close);
      if(copyCount<1){return(false);}
      if(AO_color[1]==0 && AO_color[2]==0 && AC_color[1]==0 && AC_color[2]==0 && Close[1]>Close[2] && type==0) // äâà ïîäðÿä çåëåíûõ áàðà 
        {
         CopyHigh(m_Symbol,m_Period,1,1,price_out);
         CopyTime(m_Symbol,m_Period,1,1,time_out);
        }
      if(AO_color[1]==1 && AO_color[2]==1 && AC_color[1]==1 && AC_color[2]==1 && Close[1]<Close[2] && type==1) // äâà ïîäðÿä êðàñíûõ áàðà
        {
         CopyLow(m_Symbol,m_Period,1,1,price_out);
         CopyTime(m_Symbol,m_Period,1,1,time_out);
        }
     }
   if(sub_type==1) // òðàéëèíã ñòîï ïî 5-òè áàðàì îäíîãî öâåòà
     {
      for(int y=1;y<=5;y++)
        {
         if(AO_color[y]==1 || AC_color[y]==1){find_green_zone=false;}
         if(AO_color[y]==0 || AC_color[y]==0){find_red_zone=false;}
        }
      if(find_green_zone && price_out[0]<0 && type==0)
        {
         CopyLow(m_Symbol,m_Period,1,1,price_out);  // åñëè ó íàñ íåáûëî öåíû äëÿ òðàëëà òî óñòàíàâëèâàåì åå ïîä ëîó 1-ãî áàðà (ïÿòûé çåëåíûé)
        }
      if(find_red_zone && price_out[0]<0 && type==1)
        {
         CopyHigh(m_Symbol,m_Period,1,1,price_out); // åñëè ó íàñ íåáûëî öåíû äëÿ òðàëëà òî óñòàíàâëèâàåì åå íàä õàåì 1-ãî áàðà (ïÿòûé êðàñíûé)
        }
      // ïîäòÿãèâàíèå íåñðàáîòàííîãî ñòîïà ïðè íåîáõîäèìîñòè (âîçâðàùàåì öåíó äëÿ ïåðåíîñà ñòîïëîññà)
      CopyHigh(m_Symbol,m_Period,1,1,tmp_h);
      CopyLow(m_Symbol,m_Period,1,1,tmp_l);
      if(price_out[0]>0 && type==0)
        {
         if(price_out[0]>tmp_l[0]){price_out[0]=-1;}           // ïîèäåå äîëæåí áûë ñðàáîòàòü ñòîï 
         if(price_out[0]<tmp_l[0]){price_out[0]=tmp_l[0];}    // ïåðåíîñèì ñòîï âûøå
        }
      if(price_out[0]>0 && type==1)
        {
         if(price_out[0]<tmp_h[0]){price_out[0]=-1;}               // ïîèäåå äîëæåí áûë ñðàáîòàòü ñòîï 
         if(price_out[0]>tmp_h[0]){price_out[0]=tmp_h[0];}         // ïåðåíîñèì ñòîï íèæå
        }
     }//if(sub_type==1)
   if(sub_type==2) //îãðàíè÷åíèÿ íà âõîä ïî êîëè÷åñòâó ïîäðÿä çîí
     {
      for(int t=1;t<=inp_param.max_4_dimension_zone;t++)
        {
         if((AO_color[t]==1 || AC_color[t]==1) && type==0){limit_green_zone=false;}
         if((AO_color[t]==0 || AC_color[t]==0) && type==1){limit_red_zone=false;}
        }
      if((limit_green_zone && type==0) || (limit_red_zone && type==1)){price_out[0]=-1;time_out[0]=-1;}
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| ïîèñê ñèãíàëîâ îò ïÿòíîãî èçìåðåíèÿ                              |
//+------------------------------------------------------------------+
bool C_TS_BW::FindSignal_5_dimension(int type,int sub_type,double &price_out[],datetime &time_out[])
  {
   int copyCount=-1;
   int count_2_bars=0,count_3_bars=0,n;
   double high_tmp,low_tmp;
   price_out[0]=-1;
   time_out[0]=-1;
   if(type==0)
     {
      copyCount=CopyHigh(m_Symbol,m_Period,0,10,High);
      if(copyCount<1){return(false);}
      high_tmp=High[0];
      if(High[0]>jaw[0])
        {
         for(n=1;n<10;n++)
           {
            if(high_tmp<High[n]){high_tmp=High[n];count_2_bars++;count_3_bars++;}
            if((count_2_bars==1 && sub_type==0) || (count_3_bars==2 && sub_type==1))
              {
               price_out[0]=high_tmp;
               CopyTime(m_Symbol,m_Period,n,1,time_out);
               break;
              }
           }
        }
     }
   if(type==1)
     {
      copyCount=CopyLow(m_Symbol,m_Period,0,10,Low);
      if(copyCount<1){return(false);}
      low_tmp=Low[0];
      if(Low[0]<jaw[0])
        {
         for(n=1;n<10;n++)
           {
            if(low_tmp>Low[n]){low_tmp=Low[n];count_2_bars++;count_3_bars++;}
            if((count_2_bars==1 && sub_type==0) || (count_3_bars==2 && sub_type==1))
              {
               price_out[0]=low_tmp;
               CopyTime(m_Symbol,m_Period,n,1,time_out);
               break;
              }
           }
        }
     }

   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  Ïðîâåðêà ñèãíàëîâ íà âîçìîæíîñòü âõîäà ïî òåêóùåé öåíå          |
//+------------------------------------------------------------------+
bool C_TS_BW::CheckForTradeSignal(int dimension,int type,int sub_type,double &price_out[],datetime &time_out[])
  {
   int copyCount=-1;
   copyCount=CopyHigh(m_Symbol,m_Period,0,1,High);
   if(copyCount<1){return(false);}
   copyCount=CopyLow(m_Symbol,m_Period,0,1,Low);
   if(copyCount<1){return(false);}
   switch(dimension)
     {
      case 1:   // ïðîâåðêà ôðàêòàëîâ
        {
         if((type==0 && High[0]>price_out[0] && High[0]<teeth[0] && price_out[0]>0) || // ïðîáèòèå ôðàêòàëà íà ïîêóïêó íèæå ÷åì çóáû àëëèãàòîðû - âûêëþ÷àåì äàííûé ôðàêòàë èç ðàáîòû
            (type==1 && Low[0]<price_out[0] && Low[0]>teeth[0] && price_out[0]>0)) // ïðîáèòèå ôðàêòàëà íà ïðîäàæó âûøå ÷åì çóáû àëëèãàòîðû - âûêëþ÷àåì äàííûé ôðàêòàë èç ðàáîòû
           {
            if(type==0){last_trade.fractal_up=time_out[0];}
            if(type==1){last_trade.fractal_dn=time_out[0];}
            time_out[0]=-1;
            price_out[0]=-1;
            return(false);
            break;
           }
         //--- ïîêóïêà
         if(type==0                                   // åñëè íàïðàâëåíèå Áàé
            && High[0]>price_out[0]                   // åñëè òåêóùèé Õàé áîëüøå ÷åì àêòóàëüíûé ôðàêòàë íà ïîêóïêó
            && time_out[0]!=last_trade.fractal_up     // åñëè äàííûé ñèãíàë åùå íå òîðãîâàëñÿ
            && High[0]>teeth[0]                       // åñëè òåêóùåé Õàé áîëüøå çóáîâ íà íóëåâîì áàðå
            && price_out[0]>0)                        // åñëè öåíà ôðàêòàëà áîëüøå íóëÿ (íå ñáðîøåíà â -1)
           {return(true);}                            // ïîñòóïàåò êîìàíäà íà îòïðàâêó îðäåðà
         //--- ïðîäàæà
         if(type==1                                   // åñëè íàïðàâëåíèå Cåëë
            && Low[0]<price_out[0]                    // åñëè òåêóùèé Ëîó Ìåíüøå ÷åì àêòóàëüíûé ôðàêòàë íà ïðîäàæó
            && time_out[0]!=last_trade.fractal_dn     // åñëè äàííûé ñèãíàë åùå íå òîðãîâàëñÿ
            && Low[0]<teeth[0]                        // åñëè òåêóùåé Ëîó ìåíüøå çóáîâ íà íóëåâîì áàðå
            && price_out[0]>0)                        // åñëè öåíà ôðàêòàëà áîëüøå íóëÿ (íå ñáðîøåíà â -1)
           {return(true);}                            // ïîñòóïàåò êîìàíäà íà îòïðàâêó îðäåðà
         break;
        }
      case 2:   // ïðîâåðêà ñèãíàëîâ îò ÀÎ
        {
         if(High[0]>price_out[0] &&  High[0]>teeth[0] &&  price_out[0]>0  &&  type==0  &&  // ïîêóïêó
            ((time_out[0]!=last_trade.ao_blydce && sub_type==1) ||                         // áëþäöå
            (time_out[0]!=last_trade.ao_cross_zero && sub_type==0)))                       // ïåðåñå÷åíèå íóëåîâîé ëèíèè
           {return(true);}
         if(Low[0]<price_out[0] && Low[0]<teeth[0] && price_out[0]>0 && type==1 && // ïðîäàæà
            ((time_out[0]!=last_trade.ao_blydce && sub_type==1) ||                         // áëþäöå
            (time_out[0]!=last_trade.ao_cross_zero && sub_type==0)))                       // ïåðåñå÷åíèå íóëåîâîé ëèíèè
           {return(true);}
         break;
        }
      case 3:   // ïðîâåðêà ñèãíàëîâ îò ÀC
        {
         if(High[0]>price_out[0] &&  High[0]>teeth[0] &&  price_out[0]>0  &&  type==0  &&  // ïîêóïêó
            ((time_out[0]!=last_trade.ac_2_bars && sub_type==0) ||                         // ïî äâóì çåëåíûì áàðàì
            (time_out[0]!=last_trade.ac_3_bars && sub_type==1)))                           // ïî òðåì çåëåíûì áàðàì
           {
            if(AC_color[0]==1){price_out[0]=-1;time_out[0]=-1;return(false);}              // åñëè òåêóùåé áàð íà ìîìåíò ñðàáîòêè ñèãíàëà íà ÀÎ êðàñíûé - àíóëèðóåì ñèãíàë
            else{return(true);}
           }
         if(Low[0]<price_out[0] && Low[0]<teeth[0] && price_out[0]>0 && type==1 && // ïðîäàæà
            ((time_out[0]!=last_trade.ac_2_bars && sub_type==0) ||                         // ïî äâóì êðàñíûì áàðàì
            (time_out[0]!=last_trade.ac_3_bars && sub_type==1)))                           // ïî òðåì êðàñíûì áàðàì
           {
            if(AC_color[0]==0){price_out[0]=-1;time_out[0]=-1;return(false);}              // åñëè òåêóùåé áàð íà ìîìåíò ñðàáîòêè ñèãíàëà íà ÀÎ çåëåíûé - àíóëèðóåì ñèãíàë
            else{return(true);}
           }
         break;
        }
      case 4:
        {
         if(High[0]>teeth[0]&& price_out[0]>0 && type==0 && time_out[0]!=last_trade.zone){return(true);}
         if(Low[0]<teeth[0] && price_out[0]>0 && type==1 && time_out[0]!=last_trade.zone){return(true);}
         break;
        }
      case 5:
        {
         if(High[0]>price_out[0] && High[0]>teeth[0] && price_out[0]>0 && type==0 && // ïîêóïêà
            time_out[0]!=last_trade.five_dimension && 
            ((AO_color[0]==0 && AC_color[0]==0 && sub_type==0) ||   // çåëåíàÿ çîíà è äâóõáàðîâûé ñèãíàë
            ((AO_color[0]==1 || AC_color[0]==1) && sub_type==1)))   // êðàñíàÿ èëè ñåðàÿ çîíà è òðåõáàðîâûé ñèãíàë
           {return(true);}
         if(Low[0]<price_out[0] && Low[0]<teeth[0] && price_out[0]>0 && type==1 && // ïðîäàæà
            time_out[0]!=last_trade.five_dimension && 
            ((AO_color[0]==1 && AC_color[0]==1 && sub_type==0) ||   // êðàñíàÿ  çîíà è äâóõáàðîâûé ñèãíàë
            ((AO_color[0]==0 || AC_color[0]==0) && sub_type==1)))   // çåëåíàÿ èëè ñåðàÿ çîíà è òðåõáàðîâûé ñèãíàë

           {return(true);}
         break;
        }
      break;
     }
   return(false);// ïî óìîë÷àíèþ âîçâðàçàåì false
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| îòïðâêà îðäåðà íà ñåðâåð ñ âûçîâîì  ïðîâåðêè ðåçóëüòàòà          |
//+------------------------------------------------------------------+
bool C_TS_BW::SendOrder(ENUM_ORDER_TYPE type,double &price_out[],datetime &time_out[],string comment)
  {
// ðàñ÷åò ìàãèêà
   bool needCalcMagic=true;
   //Print("mag=",(string) Magic," lot=",Lot);
   if(actual_action.fractal_open_buy || actual_action.fractal_open_sell){needCalcMagic=false;Magic=1000;actual_action.init();}
   if(actual_action.fractal_revers_buy_to_sell || actual_action.fractal_revers_sell_to_buy){needCalcMagic=false;Magic=999;actual_action.init();}
   if(needCalcMagic){CalcMagic(Magic);}

   exp_trade.SetExpertMagicNumber(Magic); // óñòàíàâëèâàåì ìàãèê
                                          //exp_trade.PrintRequest();
   double price,sl,tp=0.0;
   bool ret=false;
   s_info.RefreshRates();
// âû÷èñëÿåì íåîáõîäèìûé ëîò 

   if(Lot<0) // âíåøíèé ëîò íå óñòàíîâëåí
     {
      if(inp_param.agress_trade_mm)
        {
         if(Magic==1000){CalcLot(false,0.0,0);}  // ñòàðòîâûé 
         if(Magic==999){CalcLot(false,0.0,-1);}   // ïåðåâîðîòíûé
         if(Magic==1005){CalcLot(false,0.0,5);}   // äîëèâî÷íûé õ5
         if(Magic==1004){CalcLot(false,0.0,4);}   // äîëèâî÷íûé õ4
         if(Magic==1003){CalcLot(false,0.0,3);}   // äîëèâî÷íûé õ3
         if(Magic==1002){CalcLot(false,0.0,2);}   // äîëèâî÷íûé õ2
         if(Magic==1001){CalcLot(false,0.0,1);}   // äîëèâî÷íûé õ1
        }
      else
        {
         if(Magic>=1000 && Magic<=1005){CalcLot(false,0.0,1);}  // ñòàðòîâûé 
         if(Magic==999){CalcLot(false,0.0,-1);}   // ïåðåâîðîòíûé
        }
     }
   //Print("m=",(string) Magic," lot=",Lot);
   if(type==ORDER_TYPE_BUY)
     {
      price=s_info.Ask();
      //sl=NormalizeDouble(jaw[0],s_info.Digits());
      sl=0.0;
      if(exp_trade.PositionOpen(m_Symbol,ORDER_TYPE_BUY,Lot,price,sl,0.0,comment))
        {ret=true;}
     }
   if(type==ORDER_TYPE_SELL)
     {
      price=s_info.Bid();
      //sl=NormalizeDouble(jaw[0],s_info.Digits());
      sl=0.0;
      if(exp_trade.PositionOpen(m_Symbol,ORDER_TYPE_SELL,Lot,price,sl,0.0,comment))
        {ret=true;}
     }
   price_out[0]=-1; time_out[0]=-1;Lot=-1.0;

   if(ret)
     {
      if(actual_action.fractal_open_buy || actual_action.fractal_open_sell){actual_action.init();}
      if(actual_action.fractal_revers_buy_to_sell || actual_action.fractal_revers_sell_to_buy){actual_action.init();}
     }

   return(ret);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  Ðàñ÷åò ëîòà                                                                 |
//+------------------------------------------------------------------+
void C_TS_BW::CalcLot(bool external,double ext_lot,int type)
  {
   if(external){Lot=ext_lot;return;}
   if(!external)
     {
      if(type==0) // ñòàðòîâûé ëîò
        {if(inp_param.lot>0){Lot=inp_param.lot;}}
      if(type==-1) // ïåðåâîðîòíûé ëîò 
        {if(inp_param.lot>0){Lot=inp_param.lot+pos_info.Volume();}}
      if(type==5) // äîëèâî÷íûé õ5
        {if(inp_param.lot>0){Lot=inp_param.lot*5;}}
      if(type==4) // äîëèâî÷íûé õ4
        {if(inp_param.lot>0){Lot=inp_param.lot*4;}}
      if(type==3) // äîëèâî÷íûé õ3
        {if(inp_param.lot>0){Lot=inp_param.lot*3;}}
      if(type==2) // äîëèâî÷íûé õ2
        {if(inp_param.lot>0){Lot=inp_param.lot*2;}}
      if(type==1) // äîëèâî÷íûé õ1
        {if(inp_param.lot>0){Lot=inp_param.lot*1;}}
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  ïðîâåðêà íåîáõîäèìûõ äåéñòâèé íà òåêóùåì òèêå                   |
//+------------------------------------------------------------------+
void C_TS_BW::CheckActionOnTick(void)
  {
   bool select_pos=pos_info.Select(m_Symbol);
/// íåò òîðãîâîé ïîçèöèè ïî äàííîìó èíñòðóìåíòó -  ïðîâåðÿåì íåîáõîäèìîñòü âõîäîâ ïî ôðàêòàëàì çà  ïðåäåëàìè ïàñòè àëëèãàòîðà

   if(CheckForTradeSignal(1,0,0,last_signals.fractal_up,last_signals.fractal_up_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ôðàêòàëà
     {
      if(!select_pos){actual_action.fractal_open_buy=true;} // íåò îòêðûòûõ ïîçèöèé - âõîäèì ñòàðòîâûì ëîòîì
      if(select_pos && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_BUY && inp_param.add_1_dimension && last_signals.alligator_trend[0]){actual_action.fractal_add_buy=true;} // åñòü îòêðûòàÿ ïîçèöèÿ  Buy- âõîäèì äîëèâî÷íûì ëîòîì
      if(select_pos && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_SELL){actual_action.fractal_revers_sell_to_buy=true;} // åñòü îòêðûòàÿ ïîçèöèÿ  Sell - âõîäèì ïåðåâîðîòíûì ëîòîì 
     }
   if(CheckForTradeSignal(1,1,0,last_signals.fractal_dn,last_signals.fractal_dn_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ôðàêòàëà
     {
      if(!select_pos){actual_action.fractal_open_sell=true;} // íåò îòêðûòûõ ïîçèöèé - âõîäèì ñòàðòîâûì ëîòîì
      if(select_pos && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_SELL && inp_param.add_1_dimension  && last_signals.alligator_trend[1]){actual_action.fractal_add_sell=true;} // åñòü îòêðûòàÿ ïîçèöèÿ  Sell- âõîäèì äîëèâî÷íûì ëîòîì
      if(select_pos && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_BUY){actual_action.fractal_revers_buy_to_sell=true;} // åñòü îòêðûòàÿ ïîçèöèÿ  Buy - âõîäèì ïåðåâîðîòíûì ëîòîì 
     }
//---äîëèâêè îò 2-5 èçìåðåíèé buy
   if(select_pos && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_BUY) /// äîëèâêè â îòêðûòóþ ïîçèöèþ ïî íàïðàâëåíèþ ïîêóïêè
     {
      //---áëþäöå         
      if(inp_param.add_2_dimension_bludce && CheckForTradeSignal(2,0,1,last_signals.bludce_up,last_signals.bludce_up_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ÀÎ "áëþäöå"
        {actual_action.ao_bludce_buy=true;}
      //--- ïåðåñå÷åíèå íóëåâîé ëèíèè          
      if(inp_param.add_2_dimension_cross_zero && CheckForTradeSignal(2,0,0,last_signals.cross_zero_up,last_signals.cross_zero_up_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ÀÎ "ïåðåñå÷åíèå íóëåâîé ëèíèè"
        {actual_action.ao_cross_zero_buy=true;}
      //--- 2-õ áàðîâûé ñèãíàë íà ïîêóïêó îò ÀÑ
      if(inp_param.add_3_dimension_use_2_bars && CheckForTradeSignal(3,0,0,last_signals.ac_2_bars_up,last_signals.ac_2_bars_up_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ÀC "äâà çåëåíûõ áàðà"
        {actual_action.ac_2_bar_buy=true;}
      //--- 3-õ áàðîâûé ñèãíàë íà ïîêóïêó îò ÀÑ
      if(inp_param.add_3_dimension_use_3_bars && CheckForTradeSignal(3,0,1,last_signals.ac_3_bars_up,last_signals.ac_3_bars_up_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ÀC "òðè çåëåíûõ áàðà"
        {actual_action.ac_3_bar_buy=true;}
      //--- çåëåíàÿ çîíà
      if(inp_param.add_4_dimension_zone && CheckForTradeSignal(4,0,0,last_signals.zone_up,last_signals.zone_up_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò AO + AC (Çåëåíàÿ çîíà)
        {actual_action.zone_buy=true;}
      //--- ïÿòîå èçìåðåíèå äâóõ áàðîâûé ñèãíàë ïîêóïêà
      if(inp_param.add_5_dimension && CheckForTradeSignal(5,0,0,last_signals.five_dimension_2_bars_up,last_signals.five_dimension_2_bars_up_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ëèíèè áàëàíñà  
        {actual_action.line_balance_2_bar_buy=true;}
      //--- ïÿòîå èçìåðåíèå òðåõ áàðîâûé ñèãíàë ïîêóïêà
      if(inp_param.add_5_dimension && CheckForTradeSignal(5,0,1,last_signals.five_dimension_3_bars_up,last_signals.five_dimension_3_bars_up_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïîêóïêó ïî ñèãíàëó îò ëèíèè áàëàíñà  
        {actual_action.line_balance_3_bar_buy=true;}

     }
//--- äîëèâêè îò 2-5 èçìåðåíèé sell
   if(select_pos && (ENUM_POSITION_TYPE)pos_info.PositionType()==POSITION_TYPE_SELL) /// äîëèâêè â îòêðûòóþ ïîçèöèþ ïî íàïðàâëåíèþ ïðîäàæè
     {
      //--- áëþäöå
      if(inp_param.add_2_dimension_bludce && CheckForTradeSignal(2,1,1,last_signals.bludce_dn,last_signals.bludce_dn_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ÀÎ "áëþäöå"
        {actual_action.ao_bludce_sell=true;}
      //--- ïåðåñå÷åíèå íóëåâîé ëèíèè
      if(inp_param.add_2_dimension_cross_zero && CheckForTradeSignal(2,1,0,last_signals.cross_zero_dn,last_signals.cross_zero_dn_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ÀÎ "ïåðåñå÷åíèå íóëåâîé ëèíèè"
        {actual_action.ao_cross_zero_sell=true;}
      //--- 2-õ áàðîâûé ñèãíàë íà ïðîäàæó îò ÀÑ
      if(inp_param.add_3_dimension_use_2_bars && CheckForTradeSignal(3,1,0,last_signals.ac_2_bars_dn,last_signals.ac_2_bars_dn_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ÀC "äâà êðàñíûõ áàðà"
        {actual_action.ac_2_bar_sell=true;}
      //--- 3-õ áàðîâûé ñèãíàë íà ïîêóïêó îò ÀÑ
      if(inp_param.add_3_dimension_use_3_bars && CheckForTradeSignal(3,1,1,last_signals.ac_3_bars_dn,last_signals.ac_3_bars_dn_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ÀC "òðè êðàñíûõ áàðà"
        {actual_action.ac_3_bar_sell=true;}
      //---êðàñíàÿ çîíà
      if(inp_param.add_4_dimension_zone && CheckForTradeSignal(4,1,0,last_signals.zone_dn,last_signals.zone_dn_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò AO + AC (êðàñíàÿ çîíà)
        {actual_action.zone_sell=true;}
      //--- ïÿòîå èçìåðåíèå äâóõ áàðîâûé ñèãíàë ïðîäàæà
      if(inp_param.add_5_dimension && CheckForTradeSignal(5,1,0,last_signals.five_dimension_2_bars_dn,last_signals.five_dimension_2_bars_dn_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ëèíèè áàëàíñà  
        {actual_action.line_balance_2_bar_sell=true;}
      //--- ïÿòîå èçìåðåíèå òðåõ áàðîâûé ñèãíàë ïðîäàæà
      if(inp_param.add_5_dimension && CheckForTradeSignal(5,1,1,last_signals.five_dimension_3_bars_dn,last_signals.five_dimension_3_bars_dn_time)) // íåîáõîäèìî îòïðàâèòü îðäåð íà ïðîäàæó ïî ñèãíàëó îò ëèíèè áàëàíñà  
        {actual_action.line_balance_3_bar_sell=true;}
     }
   return;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  Âû÷èñëåíèå ìàãèêà                                               |
//+------------------------------------------------------------------+
ulong C_TS_BW::CalcMagic(ulong  &magic)
  {
   if(magic==-1) // òîëüêî ïîñëå ñòàðòà 
     {
      HistorySelect(TimeCurrent()-PeriodSeconds(PERIOD_MN1)*3,TimeCurrent());
      int countHistoryOrders=HistoryOrdersTotal();
      for(int n=countHistoryOrders-1;n>=0;n++)
        {
         h_info.SelectByIndex(n);
         magic=h_info.Magic();
         if(magic>0 && h_info.Symbol()==m_Symbol && magic>1000 && magic<=1005)
           {
            break;
           }
        }
     }
// ãåíåðèì íîâûé ìàãèê
   switch(magic)
     {
      case 999: // ïîñëåäíèì â èñòîðèè áûë ïåðåâîðîòíûé îðäåð
        {magic=1005;break;}
      case 1000: // // ïîñëåäíèì â èñòîðèè áûë îðäåð ñòàðòîâûì ëîòîì 
        {magic=1005;break;}
      case 1005: // ïîñëåäíèì â èñòîðèè áûë âòîðîé ïî ñ÷åòó îðäåð â ïîçèöèè (åñëè âêëþ÷åíî inp_param.agress_trade_mm òî õ5 ëîòîì)
        {magic=1004;break;}
      case 1004: // ïîñëåäíèì â èñòîðèè áûë òðåòèé ïî ñ÷åòó îðäåð â ïîçèöèè (åñëè âêëþ÷åíî inp_param.agress_trade_mm õ4 ëîòîì )
        {magic=1003;break;}
      case 1003: // ïîñëåäíèì â èñòîðèè áûë ÷åòâåðòûé ïî ñ÷åòó îðäåð â ïîçèöèè (åñëè âêëþ÷åíî inp_param.agress_trade_mm õ3 ëîòîì )
        {magic=1002;break;}
      case 1002: // ïîñëåäíèì â èñòîðèè áûë ïÿòûé ïî ñ÷åòó îðäåð â ïîçèöèè (åñëè âêëþ÷åíî inp_param.agress_trade_m m õ2` ëîòîì )
        {magic=1001;break;}
      case 1001: // ïîñëåäíèì â èñòîðèè áûë øåñòîé è áîëåå ïî ñ÷åòó îðäåð â ïîçèöèè (åñëè âêëþ÷åíî inp_param.agress_trade_mm  õ1 ëîòîì )
        {magic=1001;break;}
     }
   return(magic);
  }
//+------------------------------------------------------------------+
//|  Ïðèåì âíåøíåãî ñòîïà                                            |
//+------------------------------------------------------------------+
void C_TS_BW::SetStopLoss(double &stoploss)
  {StopLoss=stoploss;return;}

//+------------------------------------------------------------------+
//| Êîíåö                                                                  |
//+------------------------------------------------------------------+
