////////////////////////////////////////////////////
//           Testcase
//
//    * instantiate Test Environment
//    * instantiate Config
//
//    Should be as simple as possible for better
//    reusablity and minimum maintanence
/////////////////////////////////////////////////////

`define T        1000
`define I2C_mode "p" // fast mode plus
`define CHIP_ID  7'b1110111 // 7'b0111111

`ifndef DIRECTED
 import uvm_pkg::*;
 `include "uvm_macros.svh"
`endif

program automatic test();

   //-----------------------------------------------------------------------
   // Signal Declarations
   //-----------------------------------------------------------------------
   logic [31:0]   write_data_reg;
   logic [31:0]   read_data_reg;
   logic [31:0]   write_data[];
   logic [9:0]    reg_addr;
   logic [31:0]   read_data[];
   logic [8:0]    num_of_words;
   realtime       hclk_period;
   logic [9:0]    addr_queue[$];
   logic [31:0]   exp_wr_data;
   logic [31:0]   exp_data[*];
   logic [18:0]   pwr_mgt_wr_data;
   logic [15:0]   pwr_mgt_rd_data;
   logic          pwr_pdn;
   logic          pwr_override;

   reg fail_error = 1'b0;
   reg reading_data = 1'b0;

   real AFE1_AMP;
   real AFE1_VICM;
   real AFE2_AMP;
   real AFE2_VICM;
   real AFE3_AMP;
   real AFE3_VICM;
   real AFE4_AMP;
   real AFE4_VICM;
   real AFE5_VICM;
   real AFE5_AMP;

   real af_signal_p = 0;
   real af_signal_n = 0;
   real temp_in     = 0;
   logic signed [11:0] af_signal = 'd0;

   integer errors = 0;
   integer pts = 0;
   integer pts6 = 0, errors6 = 0;
   

   real TEMPPV;
   real TEMPNV;

   initial

     begin
     
         //$fsdbDumpMDA();     //to dump multi-dimension array.


    //force tb_top.u_top_gasket.Itop.Idigtop.digtop_no_swrap.mcu_top.sequencer_wrap.sar_ahb_intf.ch_data = af_signal;
    force tb_top.u_top_gasket.Itop.Ianatop.Idco1_top_wlvls.Iosc_dco_top.period = (1.0/48e6*1e9);
       //Set clock periods and timeout value
       `SimTimeoutValue = 440ms;
       `I2CPer    = 1us;

// EEnet at input appears to need a transition to convert the value to the desired value.
// Initialize the input signals to the AFEs to 0 and then transition to initial desired value.
// Simulation does a total of 3 transitions where the pattern is:
// 1. Original AMP and VICM
// 2. Invert the AMP to p/n for a given channel with VICM fixed
// 3. Return to original AMP and VICM

   AFE1_AMP  = 0.0;
   AFE1_VICM = 0.0;
   AFE2_AMP  = 0.0;
   AFE2_VICM = 0.0;
   AFE3_AMP  = 0.0;
   AFE3_VICM = 0.0;
   AFE4_AMP  = 0.0;
   AFE4_VICM = 0.0;
   AFE5_AMP  = 0.0;
   AFE5_VICM = 0.0;
   TEMPPV = 1.0;
   TEMPNV = 0.0;

#1;
//   AFE1_AMP  = 10e-3;
//   AFE1_VICM = 0.45;
//   AFE2_AMP  = 20e-3;
//   AFE2_VICM = 0.55;
//   AFE3_AMP  = 30e-3;
//   AFE3_VICM = 0.65;
//   AFE4_AMP  = 40e-3;
//   AFE4_VICM = 0.75;
//   AFE5_AMP  = 50e-3;
//   AFE5_VICM = 0.85;

   AFE5_AMP  = 20e-3;
   AFE5_VICM = 0.7;   
   


       `SimStart;

//force tb_top.u_top_gasket.Itop.Idigtop.digtop_no_swrap.always_on.u_msm.efuse_load_err_in = 0;
       
        #10us;     // Wait in Standby state


        force `TOP_TB.pad_in_afpV  = af_signal_p; //AFE5_VICM - AFE5_AMP; // to AFE 5
        force `TOP_TB.pad_in_afnV  = af_signal_n;

        force `TOP_TB.pad_in_s1pV  = af_signal_p; //S1
        force `TOP_TB.pad_in_s1nV  = af_signal_n;

        force `TOP_TB.pad_in_s2pV  = af_signal_p; //S2
        force `TOP_TB.pad_in_s2nV  = af_signal_n;

        force `TOP_TB.pad_in_temppV = temp_in;
        force `TOP_TB.pad_in_tempnV = TEMPNV;
       
   #10us;     // Allow VDDD to come up.  Increased to 150us for smokey
   #10us;     // Wait in Standby state

   $display($time, "\tInitializing serial I2C master.");
   i2c_master.i2c_phy.set_i2c_trans_debug(1'b0);
   i2c_master.init_i2c_bfm;   // Clear I2C master state and shadow registesr.
   i2c_master.set_i2c_address(`CHIP_ID);  // 7-bit I2C device address.
   i2c_master.set_i2c_rate(`I2C_mode, `T); // Mode (s/f/p/h), SCL period.
   #1
   i2c_master.set_i2c_info(1); // I2C INFO messages:  0 = off, 1 = on.

   //`Startup(`CHIP_ID,`I2C_mode,`T);

   #2ms

  // Transition to Active state
   i2c_master.wr_array(7'h00, '{}); //dummy write (release I2C reset)
  `MSM_MCU_EN.write(1'b1);          // Write Global_en

  // `PADIF_I2C_ADDR_IE.write(1'd0);

       //------------------------------------------------------------------
       // Instantiate I2C Transactor for validating I2C Slave to AHB Bridge
       //------------------------------------------------------------------
       //`I2CM = new(7'h10);
       //`I2CM.set_i2c_clock_per(`I2CPer);

       //------------------------------------------------------------------
       //Force the BOOTSEL low to enter Master Boot mode
       //------------------------------------------------------------------
       //`tb_tasks.set_boot_mode(1'b0);

       //Wait for ACTIVE mode
       //`tb_tasks.wait_pmu_active;

       //Wait for the software to finish
        #4100us;
        //i2c_master.wr_word(32'h40004C04,'h00008ddd);   //enable udpate       
        //i2c_master.wr_word(32'h40004C04,'h00008000);   //disable schs
        //i2c_master.wr_word(32'h40004C04,'h00008ddd);   //disable schs
        //i2c_master.wr_word(32'h40004C04,'h00000ddd);   //disable schs


        //`TOP_TB.pad_in_afnV  = AFE5_VICM + AFE5_AMP;

        //`TOP_TB.pad_in_temppV = 0.8;
        //`TOP_TB.pad_in_tempnV = TEMPNV;




        #10ms;
        if (pts == 0 || pts6 == 0 || errors != 0 || errors6 != 0)
            $error($time, "\tERROR LPF SCH1/SCH2 Wrong Result");
        else
            $display($time, "\t LPF SCH1/SCH2 Correct Result");
        
        
        
        $finish;
     end // initial begin

localparam ACC_BITS       = 18;
localparam DEX_COUNT_BITS = 6;

logic signed [ACC_BITS-1:0] sch3_mvag, sch2_mvag,  sch1_mvag, mch4_mvag,mch3_mvag,mch2_mvag,mch1_mvag;
logic        [DEX_COUNT_BITS-1:0] sch1_dexcount, sch2_dexcount, sch3_dexcount, mch4_dexcount,mch3_dexcount,mch2_dexcount,mch1_dexcount;
logic signed [13:0] sch3_max, sch2_max,sch1_max,mch4_max,mch3_max,mch2_max,mch1_max;
logic signed [13:0] sch3_min, sch2_min,sch1_min,mch4_min,mch3_min,mch2_min,mch1_min;

logic        [5:0] count_minmax_sch3, count_minmax_sch2,count_minmax_sch1;
logic        [5:0] count_minmax_mch4;
logic        [5:0] count_minmax_mch3, count_minmax_mch2,count_minmax_mch1;



assign count_minmax_sch3 = `LPF_DECIMATOR.count_minmax_ch[6];
assign count_minmax_sch2 = `LPF_DECIMATOR.count_minmax_ch[5];
assign count_minmax_sch1 = `LPF_DECIMATOR.count_minmax_ch[4];

assign count_minmax_mch4 = `LPF_DECIMATOR.count_minmax_ch[3];
assign count_minmax_mch3 = `LPF_DECIMATOR.count_minmax_ch[2];
assign count_minmax_mch2 = `LPF_DECIMATOR.count_minmax_ch[1];
assign count_minmax_mch1 = `LPF_DECIMATOR.count_minmax_ch[0];







assign sch3_max = `LPF_DECIMATOR.max_ch[6];
assign sch2_max = `LPF_DECIMATOR.max_ch[5];
assign sch1_max = `LPF_DECIMATOR.max_ch[4];
assign mch4_max = `LPF_DECIMATOR.max_ch[3];
assign mch3_max = `LPF_DECIMATOR.max_ch[2];
assign mch2_max = `LPF_DECIMATOR.max_ch[1];
assign mch1_max = `LPF_DECIMATOR.max_ch[0];

assign sch3_min = `LPF_DECIMATOR.min_ch[6];
assign sch2_min = `LPF_DECIMATOR.min_ch[5];
assign sch1_min = `LPF_DECIMATOR.min_ch[4];
assign mch4_min = `LPF_DECIMATOR.min_ch[3];
assign mch3_min = `LPF_DECIMATOR.min_ch[2];
assign mch2_min = `LPF_DECIMATOR.min_ch[1];
assign mch1_min = `LPF_DECIMATOR.min_ch[0];





assign sch3_mvag = `LPF_DECIMATOR.ch_acc_mvag[6];
assign sch2_mvag = `LPF_DECIMATOR.ch_acc_mvag[5];
assign sch1_mvag = `LPF_DECIMATOR.ch_acc_mvag[4];
assign mch4_mvag = `LPF_DECIMATOR.ch_acc_mvag[3];
assign mch3_mvag = `LPF_DECIMATOR.ch_acc_mvag[2];
assign mch2_mvag = `LPF_DECIMATOR.ch_acc_mvag[1];
assign mch1_mvag = `LPF_DECIMATOR.ch_acc_mvag[0];


assign sch3_dexcount = `LPF_DECIMATOR.ch_dex_count[6];
assign sch2_dexcount = `LPF_DECIMATOR.ch_dex_count[5];
assign sch1_dexcount = `LPF_DECIMATOR.ch_dex_count[4];

assign mch4_dexcount = `LPF_DECIMATOR.ch_dex_count[3];
assign mch3_dexcount = `LPF_DECIMATOR.ch_dex_count[2];
assign mch2_dexcount = `LPF_DECIMATOR.ch_dex_count[1];
assign mch1_dexcount = `LPF_DECIMATOR.ch_dex_count[0];

integer fid1, fid2,fid3,fid4;

logic signed [11:0] sch1_rawadc = 0;
logic signed [19:0] sch_out = '0;
logic signed [19:0] sch_exp [4:0] = {20'h5017, 20'h5017,20'h5017, 20'hc04, 20'hfa425};
logic signed [19:0] sch_exp_one = 0;
real temp_sch1 = '0;
real temp_prod = '0;



real                sch1_acc = 0;
logic [5:0]         sch1_count = 6'd15;
real                gain_dif   = 4301.0/4096.0;
real                offset_dif = -23;

real                gain_sin   =  1.5;
real                offset_sin = -23;


integer    sch1_dex_r = 0;
integer    sch2_dex_r = 0;
integer    sch3_dex_r = 0;
integer    tmp1 = 0;

//----------------------------------------
//for AF S channel - 1
initial 
 begin
 
   fid1 = $fopen("rawadc_sch1.txt","w");  
   fid2 = $fopen("sch1_dex.txt","w");  
   
    wait (`LPF_DECIMATOR.seq_global_en == 1'b1);
    //wait (`LPF_DECIMATOR.inner_timer_tick == 1'b0);
    //#1.2ms
    if (`LPF_DECIMATOR.ch_go_corr_en[4] == 1'b0) begin
       gain_dif   = 1.0;
       offset_dif = 0.0;
    end else begin
       gain_dif   = `LPF_DECIMATOR.adcdif_gain_corr/4096.0;
       offset_dif = signed'(`LPF_DECIMATOR.adcdif_offset_corr);
    end
        
        
    case(`LPF_DECIMATOR.ch_dex_cfg[4])
    4'd0:      sch1_dex_r   = 1  ;
    4'd1:      sch1_dex_r   = 5  ;
    4'd2:      sch1_dex_r   = 2  ;
    4'd3:      sch1_dex_r   = 4  ;
    4'd4:      sch1_dex_r   = 8  ;
    4'd5:      sch1_dex_r   = 16 ;
    4'd6:      sch1_dex_r   = 32 ;
    4'd7:      sch1_dex_r   = 64 ;
    4'd8:      sch1_dex_r   = 10 ;	
    default  : sch1_dex_r   = 20 ;
    endcase
    sch1_count   = (sch1_dex_r - 1'b1);

    while (1) begin
          @ (posedge `LPF_DECIMATOR.clk_seq) begin
            if(`LPF_DECIMATOR.local_sar_ahb_req && `LPF_DECIMATOR.ch_seq_id == 6'd1  && `LPF_DECIMATOR.init_avg_done[4]) begin
                   sch1_rawadc  = $signed(`LPF_DECIMATOR.raw_adc);
                   $fwrite(fid1,"%d\n", sch1_rawadc);
                   if (sch1_count == 6'd0) begin
                       temp_sch1     = sch1_acc + $signed(`LPF_DECIMATOR.raw_adc);
                       if(sch1_dex_r == 5) begin
                          temp_prod     = temp_sch1/8.0 * 6553.0/4096.0;   
                          tmp1          = $floor(temp_prod * 64 +0.5);		
						  temp_prod     = tmp1/64.0 * gain_dif + offset_dif; 
                       end else if(sch1_dex_r == 10) begin
                          temp_prod     = temp_sch1/16.0 * 6553.0/4096.0;   
                          tmp1          = $floor(temp_prod * 64 +0.5);		
						  temp_prod     = tmp1/64.0 * gain_dif + offset_dif; 
                       end else if(sch1_dex_r == 20) begin
                          temp_prod     = temp_sch1/32.0 * 6553.0/4096.0;   
                          tmp1          = $floor(temp_prod * 64 +0.5);		
						  temp_prod     = tmp1/64.0 * gain_dif + offset_dif; 
                       end else
                          temp_prod     = temp_sch1/sch1_dex_r * gain_dif + offset_dif;
                       
                       sch_exp_one  <= $floor(temp_prod * 64+0.5);    //rounding here; truncation only use $floor
                       sch1_acc     <= 20'd0;
                       sch1_count   <= (sch1_dex_r - 1'b1);
                   end else begin
                       sch1_count   <= sch1_count - 1'b1;
                       sch1_acc     <= sch1_acc + $signed(`LPF_DECIMATOR.raw_adc);
                   end
            end                 
        end
    end
end


initial 
begin

    wait (`LPF_DECIMATOR.seq_global_en == 1'b1);
        while (1) begin

            @ (posedge `LPF_DECIMATOR.clk_lpf) begin
            if (`LPF_DECIMATOR.lpf_dcm_rdy  && `LPF_DECIMATOR.ch_seq_id == 6'd1 && `LPF_DECIMATOR.init_avg_done[4])  begin
                  sch_out = signed'(`LPF_DECIMATOR.sch1_dex_out_in);
                  $fwrite(fid2,"%d\n", sch_out);
                  
                  $display($time, "\t LPF DCM SCH1 Output =%h,     Expected Output = %h", sch_out, sch_exp_one);
                  if( (sch_out != sch_exp_one) )
                      errors = errors + 1;
                        
                  pts = pts + 1'b1;
                  if (pts == 'd10 ) begin
                     if (errors == 0)
                         $display($time, "\t LPF SCH1 Correct Result");
                     else
                         $error($time, "\tERROR LPF SCH1 Wrong Result");                                                 
                     //$finish;
                  end    
            end               
          end
        end
end


//----------------------------------------
//for SCH2 EXT TEMP
//----------------------------------------

real                sch2_acc = 0, temp_sch2 = 0, temp_prod6 =0 ;
integer             tmp6 = 0;
logic [5:0]         sch2_count = 6'd7;
logic signed [19:0] sch2_exp_one = 0, sch2_out = 0;
logic signed [19:0] sch2_exp_one_neg = 0;
initial 

begin
   fid3 = $fopen("rawadc_sch2.txt","w");  
   fid4 = $fopen("sch2_dex.txt","w");  

    wait (`LPF_DECIMATOR.seq_global_en == 1'b1);
    //#1.2ms
    if (`LPF_DECIMATOR.ch_go_corr_en[5] == 1'b0) begin
       gain_sin   = 1.0;
       offset_sin = 0.0;
	end else if(`LPF_DECIMATOR.sch_mapping[1] == 5'd6) begin
       gain_sin   = `LPF_DECIMATOR.adcsin_gain_corr/4096.0;
       offset_sin = signed'(`LPF_DECIMATOR.adcsin_offset_corr);
	end else begin
       gain_sin   = `LPF_DECIMATOR.adcdif_gain_corr/4096.0;
       offset_sin = signed'(`LPF_DECIMATOR.adcdif_offset_corr);		   
    end
	
    
    case(`LPF_DECIMATOR.ch_dex_cfg[5])
    4'd0:      sch2_dex_r   = 1  ;
    4'd1:      sch2_dex_r   = 5  ;
    4'd2:      sch2_dex_r   = 2  ;
    4'd3:      sch2_dex_r   = 4  ;
    4'd4:      sch2_dex_r   = 8  ;
    4'd5:      sch2_dex_r   = 16 ;
    4'd6:      sch2_dex_r   = 32 ;
    4'd7:      sch2_dex_r   = 64 ;
    4'd8:      sch2_dex_r   = 10 ;	
    default  : sch2_dex_r   = 20 ;
    endcase
    sch2_count  = (sch2_dex_r-1'b1); //6'd7;



    while (1) begin
          @ (posedge `LPF_DECIMATOR.clk_seq) begin
            if(`LPF_DECIMATOR.local_sar_ahb_req && `LPF_DECIMATOR.ch_seq_id == `LPF_DECIMATOR.sch_mapping[1]  && `LPF_DECIMATOR.init_avg_done[5]) begin
                   $fwrite(fid3,"%d\n", `LPF_DECIMATOR.raw_adc);
                   if (sch2_count == 6'd0) begin
                       temp_sch2      = sch2_acc + $signed({`LPF_DECIMATOR.raw_adc});
                       
                       if(sch2_dex_r == 5) begin
                          temp_prod6     = temp_sch2/8.0*6553.0/4096.0; 
                          tmp6           = $floor(temp_prod6 * 64 +0.5);					  
                          temp_prod6     = tmp6/64.0 * gain_sin + offset_sin;                    
                          sch2_exp_one  <= $floor(temp_prod6 * 64+0.5);
                      end else if(sch2_dex_r == 10) begin
                          temp_prod6     = temp_sch2/16.0*6553.0/4096.0; 
                          tmp6           = $floor(temp_prod6 * 64 +0.5);					  
                          temp_prod6     = tmp6/64.0 * gain_sin + offset_sin;                    
                          sch2_exp_one  <= $floor(temp_prod6 * 64+0.5);
                      end else if(sch2_dex_r == 20) begin
                          temp_prod6     = temp_sch2/32.0*6553.0/4096.0; 
                          tmp6           = $floor(temp_prod6 * 64 +0.5);					  
                          temp_prod6     = tmp6/64.0 * gain_sin + offset_sin;                    
                          sch2_exp_one  <= $floor(temp_prod6 * 64+0.5);
                       end else begin
                          temp_prod6     = temp_sch2/sch2_dex_r * gain_sin + offset_sin;                          						
                          sch2_exp_one  <= $floor(temp_prod6 * 64+0.5);
					   end
					   
                       sch2_acc      <= 20'd0;
                       sch2_count    <= (sch2_dex_r-1'b1); //6'd7;
                   end else begin
                       sch2_count    <= sch2_count - 1'b1;
                       sch2_acc      <= sch2_acc + $signed({`LPF_DECIMATOR.raw_adc});
                   end
            end                 
        end
    end
end


initial 
begin

    wait (`LPF_DECIMATOR.seq_global_en == 1'b1);
        while (1) begin
            @(posedge `LPF_DECIMATOR.clk_seq) begin
               if(`LPF_DECIMATOR.local_sar_ahb_req && (sch2_dexcount == (sch2_dex_r-1'b1) )  && (`LPF_DECIMATOR.ch_seq_id == `LPF_DECIMATOR.sch_mapping[1]) && (`LPF_DECIMATOR.init_avg_done[5]) ) begin         
                      sch2_out = signed'(`LPF_DECIMATOR.sch2_dex_out_in);
                      $fwrite(fid4,"%d\n", sch2_out);
                      $display($time, "\t LPF DCM SCH2 Output =%h,     Expected Output = %h", sch2_out, sch2_exp_one);
                      if( sch2_out != sch2_exp_one )
                           errors6 = errors6 + 1;
                       
                      pts6 = pts6 + 1'b1;
                      if (pts6 == 'd50 ) begin
                          if (errors6 == 0)
                              $display($time, "\t LPF SCH2 Correct Result");
                          else
                              $error($time, "\tERROR LPF SCH2 Wrong Result");
                        
                        
                         // $finish;
                      end
               end                 
            end
        end
end


//to generate sine wave (10KHz) at 80KS/s
real freq_clk   = 80e3;

logic clk_80khz = 1'b0;
initial
begin
 clk_80khz = 1'b0;

 while(1) begin 
   #(0.5*1e9/freq_clk) clk_80khz <= ~clk_80khz;
 end
end

  

integer fid30;

real it = 0;
real tmp = 0;

initial

begin 
  #2ms
  fid30 = $fopen("sine_gen.txt","w");  
  while(1) begin  
   //@ (posedge tb_top.u_top_gasket.Itop.Idigtop.digtop_no_swrap.mcu_top.sequencer_wrap.clk) begin
   @ (posedge clk_80khz) begin
       tmp          = ($sin(2*3.14159*100/freq_clk*it) * 0.0039);                   //FULL SCALE out
       //tmp          = ($sin(2*3.141592653589793*100/freq_clk*it) * 0.699); 
       af_signal_p  = AFE5_VICM + tmp ;
       af_signal_n  = AFE5_VICM - tmp ;
       temp_in      = $sin(2*3.14159*100/freq_clk*it) * 0.695 + 0.7;
       af_signal    = tmp * 2 /1.4*2048;
       
       //$fwrite(fid30,"%d\n", af_signal);

       it <= it + 1;       
   end  //clk
   end  //while 
end



//----------------------------------------
//for SCH3 AF sensor
//----------------------------------------

real                gain_sin3, offset_sin3;
real                sch3_acc = 0, temp_sch3 = 0, temp_prod3 =0 ;
integer             temp3 = 0, errors3 = 0, pts3 = 0, fid33, fid40;
logic [5:0]         sch3_count = 6'd7;
logic signed [19:0] sch3_exp_one = 0, sch3_out = 0;
logic signed [19:0] sch3_exp_one_neg = 0;

initial 

begin
   fid33 = $fopen("rawadc_sch3.txt","w");  
   fid40 = $fopen("sch3_dex.txt","w");  

    wait (`LPF_DECIMATOR.seq_global_en == 1'b1);
    //#1.2ms
    if (`LPF_DECIMATOR.ch_go_corr_en[6] == 1'b0) begin
       gain_sin3   = 1.0;
       offset_sin3 = 0.0;
	end else begin
       gain_sin3   = `LPF_DECIMATOR.adcdif_gain_corr/4096.0;
       offset_sin3 = signed'(`LPF_DECIMATOR.adcdif_offset_corr);
    end
	
    
    case(`LPF_DECIMATOR.ch_dex_cfg[6])
    4'd0:      sch3_dex_r   = 1  ;
    4'd1:      sch3_dex_r   = 5  ;
    4'd2:      sch3_dex_r   = 2  ;
    4'd3:      sch3_dex_r   = 4  ;
    4'd4:      sch3_dex_r   = 8  ;
    4'd5:      sch3_dex_r   = 16 ;
    4'd6:      sch3_dex_r   = 32 ;
    4'd7:      sch3_dex_r   = 64 ;
    4'd8:      sch3_dex_r   = 10 ;	
    default  : sch3_dex_r   = 20 ;
    endcase
    sch3_count  = (sch3_dex_r-1'b1); //6'd7;



    while (1) begin
          @ (posedge `LPF_DECIMATOR.clk_seq) begin
            if(`LPF_DECIMATOR.local_sar_ahb_req && `LPF_DECIMATOR.ch_seq_id == 5'h3  && `LPF_DECIMATOR.init_avg_done[6]) begin
                   $fwrite(fid33,"%d\n", `LPF_DECIMATOR.raw_adc);
                   if (sch3_count == 6'd0) begin
                       temp_sch3      = sch3_acc + $signed({`LPF_DECIMATOR.raw_adc});
                       
                       if(sch3_dex_r == 5) begin
                          temp_prod3     = temp_sch3/8.0*6553.0/4096.0; 
                          temp3           = $floor(temp_prod3 * 64 +0.5);					  
                          temp_prod3     = temp3/64.0 * gain_sin3 + offset_sin3;                    
                          sch3_exp_one  <= $floor(temp_prod3 * 64+0.5);
                      end else if(sch3_dex_r == 10) begin
                          temp_prod3     = temp_sch3/16.0*6553.0/4096.0; 
                          temp3           = $floor(temp_prod3 * 64 +0.5);					  
                          temp_prod3     = temp3/64.0 * gain_sin3 + offset_sin3;                    
                          sch3_exp_one  <= $floor(temp_prod3 * 64+0.5);
                      end else if(sch3_dex_r == 20) begin
                          temp_prod3     = temp_sch3/32.0*6553.0/4096.0; 
                          temp3           = $floor(temp_prod3 * 64 +0.5);					  
                          temp_prod3     = temp3/64.0 * gain_sin3 + offset_sin3;                    
                          sch3_exp_one  <= $floor(temp_prod3 * 64+0.5);
                       end else begin
                          temp_prod3     = temp_sch3/sch3_dex_r * gain_sin3 + offset_sin3;                          						
                          sch3_exp_one  <= $floor(temp_prod3 * 64+0.5);
					   end
					   
                       sch3_acc      <= 20'd0;
                       sch3_count    <= (sch3_dex_r-1'b1); //6'd7;
                   end else begin
                       sch3_count    <= sch3_count - 1'b1;
                       sch3_acc      <= sch3_acc + $signed({`LPF_DECIMATOR.raw_adc});
                   end
            end                 
        end
    end
end


initial 
begin

    wait (`LPF_DECIMATOR.seq_global_en == 1'b1);
        while (1) begin
            @(posedge `LPF_DECIMATOR.clk_seq) begin
               if(`LPF_DECIMATOR.local_sar_ahb_req && (sch3_dexcount == (sch3_dex_r-1'b1) )  && (`LPF_DECIMATOR.ch_seq_id == 5'h3) && (`LPF_DECIMATOR.init_avg_done[6]) ) begin         
                      sch3_out = signed'(`LPF_DECIMATOR.sch3_dex_out_in);
                      $fwrite(fid40,"%d\n", sch3_out);
                      $display($time, "\t LPF DCM SCH3 Output =%h,     Expected Output = %h", sch3_out, sch3_exp_one);
                      if( sch3_out != sch3_exp_one )
                           errors3 = errors3 + 1;
                       
                      pts3 = pts3 + 1'b1;
                      if (pts3 == 'd50 ) begin
                          if (errors3 == 0)
                              $display($time, "\t LPF SCH3 Correct Result");
                          else
                              $error($time, "\tERROR LPF SCH3 Wrong Result");
                        
                        
                         // $finish;
                      end
               end                 
            end
        end
end



endprogram // test


