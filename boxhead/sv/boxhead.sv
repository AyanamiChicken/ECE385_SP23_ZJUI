//-------------------------------------------------------------------------
//      boxhead
//-------------------------------------------------------------------------


`define ENEMY_NUM 4
module boxhead( input               CLOCK_50,
             input        [3:0]  KEY,          //bit 0 is set up as Reset
             output logic [6:0]  HEX0, HEX1, HEX2, HEX3,HEX4,HEX5,HEX6,HEX7,
             // VGA Interface 
             output logic [7:0]  VGA_R,        //VGA Red
                                 VGA_G,        //VGA Green
                                 VGA_B,        //VGA Blue
             output logic        VGA_CLK,      //VGA Clock
                                 VGA_SYNC_N,   //VGA Sync signal
                                 VGA_BLANK_N,  //VGA Blank signal
                                 VGA_VS,       //VGA virtical sync signal
                                 VGA_HS,       //VGA horizontal sync signal
             // CY7C67200 Interface
             inout  wire  [15:0] OTG_DATA,     //CY7C67200 Data bus 16 Bits
             output logic [1:0]  OTG_ADDR,     //CY7C67200 Address 2 Bits
             output logic        OTG_CS_N,     //CY7C67200 Chip Select
                                 OTG_RD_N,     //CY7C67200 Write
                                 OTG_WR_N,     //CY7C67200 Read
                                 OTG_RST_N,    //CY7C67200 Reset
             input               OTG_INT,      //CY7C67200 Interrupt
             // SDRAM Interface for Nios II Software
             output logic [12:0] DRAM_ADDR,    //SDRAM Address 13 Bits
             inout  wire  [31:0] DRAM_DQ,      //SDRAM Data 32 Bits
             output logic [1:0]  DRAM_BA,      //SDRAM Bank Address 2 Bits
             output logic [3:0]  DRAM_DQM,     //SDRAM Data Mast 4 Bits
             output logic        DRAM_RAS_N,   //SDRAM Row Address Strobe
                                 DRAM_CAS_N,   //SDRAM Column Address Strobe
                                 DRAM_CKE,     //SDRAM Clock Enable
                                 DRAM_WE_N,    //SDRAM Write Enable
                                 DRAM_CS_N,    //SDRAM Chip Select
                                 DRAM_CLK,     //SDRAM Clock
             //Audio
			 input	AUD_ADCDAT,
			 input AUD_DACLRCK,
			 input AUD_ADCLRCK,
			 input AUD_BCLK,
			 output logic AUD_DACDAT,
			 output logic AUD_XCK,
			 output logic I2C_SCLK,
			 output logic I2C_SDAT
                    );
    
    logic Reset_h, Clk;
    logic [15:0] keycode;
    
    assign Clk = CLOCK_50;
    always_ff @ (posedge Clk) begin
        Reset_h <= ~(KEY[0]);        // The push buttons are active low
    end
    
    logic [1:0] hpi_addr;
    logic [15:0] hpi_data_in, hpi_data_out;
    logic hpi_r, hpi_w, hpi_cs, hpi_reset;
    
    // Interface between NIOS II and EZ-OTG chip
    hpi_io_intf hpi_io_inst(
                            .Clk(Clk),
                            .Reset(Reset_h),
                            // signals connected to NIOS II
                            .from_sw_address(hpi_addr),
                            .from_sw_data_in(hpi_data_in),
                            .from_sw_data_out(hpi_data_out),
                            .from_sw_r(hpi_r),
                            .from_sw_w(hpi_w),
                            .from_sw_cs(hpi_cs),
                            .from_sw_reset(hpi_reset),
                            // signals connected to EZ-OTG chip
                            .OTG_DATA(OTG_DATA),    
                            .OTG_ADDR(OTG_ADDR),    
                            .OTG_RD_N(OTG_RD_N),    
                            .OTG_WR_N(OTG_WR_N),    
                            .OTG_CS_N(OTG_CS_N),
                            .OTG_RST_N(OTG_RST_N)
    );
     
     nios_system nios_system(
                             .clk_clk(Clk),         
                             .reset_reset_n(1'b1),    // Never reset NIOS
                             .sdram_wire_addr(DRAM_ADDR), 
                             .sdram_wire_ba(DRAM_BA),   
                             .sdram_wire_cas_n(DRAM_CAS_N),
                             .sdram_wire_cke(DRAM_CKE),  
                             .sdram_wire_cs_n(DRAM_CS_N), 
                             .sdram_wire_dq(DRAM_DQ),   
                             .sdram_wire_dqm(DRAM_DQM),  
                             .sdram_wire_ras_n(DRAM_RAS_N),
                             .sdram_wire_we_n(DRAM_WE_N), 
                             .sdram_clk_clk(DRAM_CLK),
                             .keycode_export(keycode),  
                             .otg_hpi_address_export(hpi_addr),
                             .otg_hpi_data_in_port(hpi_data_in),
                             .otg_hpi_data_out_port(hpi_data_out),
                             .otg_hpi_cs_export(hpi_cs),
                             .otg_hpi_r_export(hpi_r),
                             .otg_hpi_w_export(hpi_w),
                             .otg_hpi_reset_export(hpi_reset)
    );
    
    // Audio Part
    // INIT: input logic for interface, generated by audio.
    // INIT_FINISH: Output logic for interface.
    // data_over: sample sync pulse
    logic INIT_FINISH, data_over, INIT;
    // background music content and play frequency
    // Add is the pointer to the memory of target audio.
	logic [16:0] Add;
    logic INIT_BGM;
    logic [16:0] BGM_content;
    // output audio signal, to the interface to play
	logic [16:0] music_content;
    logic [16:0] music_frequency;
    always_comb begin
		music_frequency = 16'd84;
	end
    // The Pikachu attack sound effect:
    // Note: Pike_enable is used to enable the sound 'Pi-ka'
    // pika_enable = 4'd01: enable to produce sound
    // otherwise don't.
    logic pika_enable;
    logic [16:0] pika_add;
    logic [16:0] pika_content;
    logic [16:0] pika_frequency;
    logic INIT_pika;


    always_comb begin
        pika_frequency = 16'd31;
    end
    // background music display
    audio audio1 (.*, .Reset(Reset_h));
	music music1 (.*, .music_content(BGM_content));
    
    // Pikachu memory loading:
    pika_sound pikaROM (.*, .pika_content(pika_content));
    pika_audio pikaAUD (.*, .Reset(Reset_h));

    // Gengar attacked sound
    logic gengar_enable;
    logic [16:0] gengar_add;
    logic [16:0] gengar_content;
    logic [16:0] gengar_frequency;
    logic INIT_gengar;

    always_comb begin
        gengar_frequency = 16'd20;
    end
    
    // Gengar memory loading:
    gengar_sound gengarROM (.*, .gengar_content(gengar_content));
    gengar_audio gengarAUD (.*, .Reset(Reset_h));

    // electrical attack sound
    logic ele_enable;
    logic [16:0] ele_add;
    logic [16:0] ele_content;
    logic [16:0] ele_frequency;
    logic INIT_ele;

    always_comb begin
        ele_frequency = 16'd20;
    end
    
    // electrical attack effect memory loading:
    ele_sound eleROM (.*, .ele_content(ele_content));
    ele_audio eleAUD (.*, .Reset(Reset_h));

    // test sound effects enable trigger
    // assign pika_enable = 4'd00;
    // assign gengar_enable = 4'd00;
    // assign ele_enable = 4'd01;

    // generate overall control
    // signal interacting with interface
    
    assign music_content =  pika_content + BGM_content + gengar_content + ele_content;


    always_comb begin
        INIT = INIT_BGM | INIT_pika | INIT_gengar | INIT_ele;
    end


    // interface connection, Audio display
    audio_interface music_int ( .LDATA(music_content), 
								.RDATA(music_content),
								.CLK(Clk),
								.Reset(Reset_h), 
								.INIT(INIT),
								.INIT_FINISH(INIT_FINISH),
								.adc_full(adc_full),
								.data_over(data_over),
								.AUD_MCLK(AUD_XCK),
								.AUD_BCLK(AUD_BCLK),     
								.AUD_ADCDAT(AUD_ADCDAT),
								.AUD_DACDAT(AUD_DACDAT),
								.AUD_DACLRCK(AUD_DACLRCK),
								.AUD_ADCLRCK(AUD_ADCLRCK),
								.I2C_SDAT(I2C_SDAT),
								.I2C_SCLK(I2C_SCLK),
								.ADCDATA(ADCDATA)
	);

    // VGA part
    logic [9:0] DrawX, DrawY;
    logic [8:0] PixelX, PixelY;
    logic game_frame_clk_rising_edge;

    logic [31:0] bkg_address;
    logic [12:0] player_address;
    logic [13:0] enemy_address [`ENEMY_NUM];
    logic [8:0] attack_address;
    logic [10:0] attack2_address;
    logic [8:0] enemy_attack_address [`ENEMY_NUM];
    logic [8:0] existed_enemy_attack_address;
    logic [14:0] game_over_address;
    logic [17:0] game_start_address;
    logic [14:0] score_address;
    logic [14:0] level_address;
    logic [8:0] blood_address;
    logic [11:0] blackboard_address;

    logic [4:0] bkg_index;
    logic [4:0] player_index;
    logic [4:0] enemy_index [`ENEMY_NUM];
    logic [4:0] attack_index;
    logic [4:0] attack2_index;
    // logic [4:0] enemy_attack_index [`ENEMY_NUM];
    logic [4:0] existed_enemy_attack_index;
    logic [4:0] game_over_index;
    logic [4:0] game_start_index;
    logic [4:0] score_index;
    logic [4:0] level_index;
    logic [4:0] blood_index;
    logic [4:0] blackboard_index;

    logic is_player;
    logic is_enemy [`ENEMY_NUM];
    logic is_attack;
    logic is_attack2;
    logic is_enemy_attack [`ENEMY_NUM];
    logic existed_is_enemy_attack;
    logic is_game_over; // Not determine if game is over. Instead used as sprite
                        // Game_Over_On determines is game is over
    logic is_game_start; // Same as is_game_over
    logic is_score;
    logic is_level;
    logic is_blood;
    logic is_blackboard;

    logic [8:0] Player_X, Player_Y;
    logic [1:0] Player_Direction;
    logic Attack_On;
    logic Attack2_On;
    logic Enemy_Attack_On [`ENEMY_NUM];
    logic Game_Over_On;
    logic Game_Start_On; // Indicate whether start interface is displayed
    logic [8:0] Attack_X, Attack_Y;
    logic [8:0] Attack2_X, Attack2_Y;
    logic Enemy_Alive [`ENEMY_NUM];
    logic [8:0] Enemy_X [`ENEMY_NUM];
    logic [8:0] Enemy_Y [`ENEMY_NUM];
    logic Enemy_Attack_Ready [`ENEMY_NUM];
    logic Enemy_Is_Attacked [`ENEMY_NUM];
    logic Enemy_Is_Attacked2 [`ENEMY_NUM];
    logic [3:0] Game_Level;

    logic [9:0] Enemy_Score [`ENEMY_NUM];
    logic [9:0] Total_Score;
    logic [9:0] Enemy_Respawn_Unit_Time;
    logic [9:0] Enemy_Total_Damage [`ENEMY_NUM];
    logic [9:0] Enemy_Total_Damage_God [`ENEMY_NUM];
    logic [12:0] All_Enemy_Total_Damage;
    logic [12:0] All_Enemy_Total_Damage_God;
    parameter [9:0] Player_Full_Blood = 10'd50;
    parameter [9:0] Player_Full_Blood_God = 10'd300;
    logic [9:0] Player_Blood;


    logic Godmode_On;

    assign PixelX = DrawX[9:1];
    assign PixelY = DrawY[9:1];

    assign bkg_address = PixelX + PixelY * 320;

    // Audio interface
    // Pika is attacked
    assign pika_enable = Enemy_Attack_On[0] | Enemy_Attack_On[1] | Enemy_Attack_On[2] | Enemy_Attack_On[3];
    assign gengar_enable = Enemy_Is_Attacked[0] | Enemy_Is_Attacked[1] | Enemy_Is_Attacked[2] | Enemy_Is_Attacked[3] | 
                            Enemy_Is_Attacked2[0] | Enemy_Is_Attacked2[1] | Enemy_Is_Attacked2[2] | Enemy_Is_Attacked2[3];
    assign ele_enable = Attack_On | Attack2_On;


    vga_controller vga_controller_inst(
        .*,
        .Reset(Reset_h),
        .hs(VGA_HS),
        .vs(VGA_VS),
        .pixel_clk(VGA_CLK),
        .blank(VGA_BLANK_N),
        .sync(VGA_SYNC_N)
    );
    // Comment to decrease compile time
    backgroundROM backgroundROM_inst(
        .*,
        .read_address(bkg_address),
        .data_Out(bkg_index)
    );

    // assign bkg_index = 1;

    game_frame_clk game_frame_clk_inst(
        .Clk(Clk),
        .frame_clk(VGA_VS),
        .Game_Start_On(Game_Start_On),
        .Game_Over_On(Game_Over_On),
        // Output
        .game_frame_clk_rising_edge(game_frame_clk_rising_edge)
    );

    player player_inst(
        .*,
        .Reset(Reset_h),
        .game_frame_clk_rising_edge(game_frame_clk_rising_edge),
        .keycode(keycode),
        .Godmode_On(Godmode_On),
        .Attack_On(Attack_On),
        .is_obj(is_player),
        .Obj_address(player_address),
        .Obj_X_Pos(Player_X),
        .Obj_Y_Pos(Player_Y),
        .Obj_Direction(Player_Direction)
    );

    playerROM playerROM_inst(
        .Clk(Clk),
        .read_address(player_address),
        .data_Out(player_index)
    );


    genvar i;
    generate 
        for (i = 0; i < `ENEMY_NUM; i++) begin: multi_enemy
            enemy #(.id(i)) enemy_inst(
                .Clk(Clk),
                .Reset(Reset_h),
                .game_frame_clk_rising_edge(game_frame_clk_rising_edge),
                .keycode(keycode),
                .PixelX(PixelX),
                .PixelY(PixelY),
                .is_alive(Enemy_Alive[i]),
                .Player_X(Player_X),
                .Player_Y(Player_Y),
                .Enemy_Is_Attacked(Enemy_Is_Attacked[i]),
                .Enemy_Is_Attacked2(Enemy_Is_Attacked2[i]),
                // Output
                .is_obj(is_enemy[i]),
                .Obj_address(enemy_address[i]),
                .Obj_X_Pos(Enemy_X[i]),
                .Obj_Y_Pos(Enemy_Y[i]),
                .Enemy_Attack_Ready_in(Enemy_Attack_Ready[i])
            );
        end
    endgenerate    

    enemyROM enemyROM_inst(
        .Clk(Clk),
        .read_address0(enemy_address[0]),
        .read_address1(enemy_address[1]),
        .data_Out0(enemy_index[0]),
        .data_Out1(enemy_index[1])
    );

    enemyROM enemyROM_inst1(
        .Clk(Clk),
        .read_address0(enemy_address[2]),
        .read_address1(enemy_address[3]),
        .data_Out0(enemy_index[2]),
        .data_Out1(enemy_index[3])
    );
    
    attack attack_inst(
        .*,
        .Reset(Reset_h),
        .game_frame_clk_rising_edge(game_frame_clk_rising_edge),
        .keycode(keycode),
        .Game_Level(Game_Level),
        // Output
        .is_obj(is_attack),
        .Obj_address(attack_address),
        .Obj_On(Attack_On),
        .Obj_X_Pos(Attack_X),
        .Obj_Y_Pos(Attack_Y)
    );

    attack2 attack2_inst(
        .*,
        .Reset(Reset_h),
        .game_frame_clk_rising_edge(game_frame_clk_rising_edge),
        .keycode(keycode),
        .One_Enemy_Is_Attacked2(Enemy_Is_Attacked2[0] | Enemy_Is_Attacked2[1] | Enemy_Is_Attacked2[2] | Enemy_Is_Attacked2[3]),
        // Output
        .is_obj(is_attack2),
        .Obj_address(attack2_address),
        .Obj_On(Attack2_On),
        .Obj_X_Pos(Attack2_X),
        .Obj_Y_Pos(Attack2_Y)
    );

    attackROM attackROM_inst(
        .Clk(Clk),
        .read_address(attack_address),
        .data_Out(attack_index)
    );

    attack2ROM attack2ROM_inst(
        .Clk(Clk),
        .read_address(attack2_address),
        .data_Out(attack2_index)
    );

    logic Enemy_Attack_Valid [`ENEMY_NUM];
    genvar k;
    generate 
        for (k = 0; k < `ENEMY_NUM; k++) begin: enemy_attack
            enemy_attack enemy_attack_inst(
                .Clk(Clk),
                .Reset(Reset_h),
                .game_frame_clk_rising_edge(game_frame_clk_rising_edge),
                .Player_X(Player_X),
                .Player_Y(Player_Y),
                .PixelX(PixelX),
                .PixelY(PixelY),
                .Enemy_Attack_Ready(Enemy_Attack_Ready[k]),
                // Output
                .is_obj(is_enemy_attack[k]),
                .Obj_address(enemy_attack_address[k]),
                .Obj_On(Enemy_Attack_On[k]),
                .Enemy_Attack_Valid(Enemy_Attack_Valid[k])
            );
        end
    endgenerate

    // Used to reduce size of ROM and read/write ROM
    always_comb begin
        if(Enemy_Attack_On[0]) begin
            existed_enemy_attack_address = enemy_attack_address[0];
            existed_is_enemy_attack = is_enemy_attack[0];
        end
        else if (Enemy_Attack_On[1]) begin
            existed_enemy_attack_address = enemy_attack_address[1];
            existed_is_enemy_attack = is_enemy_attack[1];
        end
        else if (Enemy_Attack_On[2]) begin
            existed_enemy_attack_address = enemy_attack_address[2];
            existed_is_enemy_attack = is_enemy_attack[2];
        end
        else if (Enemy_Attack_On[3]) begin
            existed_enemy_attack_address = enemy_attack_address[3];
            existed_is_enemy_attack = is_enemy_attack[3];
        end
        else begin
            existed_enemy_attack_address = 9'b0;
            existed_is_enemy_attack = 1'b0;
        end
    end

    enemy_attackROM enemy_attackROM_inst(
        .Clk(Clk),
        .read_address(existed_enemy_attack_address),
        .data_Out(existed_enemy_attack_index)
    );


    genvar j;
    generate
        for (j = 0; j < `ENEMY_NUM; j++) begin: game
            gamelogic #(.id(j)) gamelogic_inst(
                .Clk(Clk),
                .Reset(Reset_h),
                .game_frame_clk_rising_edge(game_frame_clk_rising_edge),
                .Player_X(Player_X),
                .Player_Y(Player_Y),
                .Attack_X(Attack_X),
                .Attack_Y(Attack_Y),
                .Attack2_X(Attack2_X),
                .Attack2_Y(Attack2_Y),
                .Enemy_X(Enemy_X[j]),
                .Enemy_Y(Enemy_Y[j]),
                .Player_Direction(Player_Direction),
                .Attack_On(Attack_On),
                .Attack2_On(Attack2_On),
                .Enemy_Attack_On(Enemy_Attack_On[j]),
                .Godmode_On(Godmode_On),
                .Enemy_Respawn_Unit_Time(Enemy_Respawn_Unit_Time),
                .Enemy_Attack_Valid(Enemy_Attack_Valid[j]),
                // Output
                .Enemy_Alive(Enemy_Alive[j]),
                .Enemy_Score(Enemy_Score[j]),
                .Enemy_Total_Damage(Enemy_Total_Damage[j]),
                .Enemy_Total_Damage_God(Enemy_Total_Damage_God[j]),
                .Enemy_Is_Attacked(Enemy_Is_Attacked[j]),
                .Enemy_Is_Attacked2(Enemy_Is_Attacked2[j])
            );
        end
    endgenerate

    assign Total_Score = Enemy_Score[0] + Enemy_Score[1] + Enemy_Score[2] + Enemy_Score[3];

    assign All_Enemy_Total_Damage = (Enemy_Total_Damage[0] + Enemy_Total_Damage[1] + Enemy_Total_Damage[2] + Enemy_Total_Damage[3]);
    assign All_Enemy_Total_Damage_God = (Enemy_Total_Damage_God[0] + Enemy_Total_Damage_God[1] + Enemy_Total_Damage_God[2] + Enemy_Total_Damage_God[3]);

    always_comb begin
        if (Godmode_On) begin
            if (All_Enemy_Total_Damage_God <= Player_Full_Blood_God) begin
                Player_Blood = Player_Full_Blood_God - All_Enemy_Total_Damage_God;
                Game_Over_On = 1'b0;
            end
            else begin
                Player_Blood = 0;
                Game_Over_On = 1'b1;
            end
        end
        else begin
            if (All_Enemy_Total_Damage < Player_Full_Blood) begin
                Player_Blood = Player_Full_Blood - All_Enemy_Total_Damage;
                Game_Over_On = 1'b0;
            end
            else begin
                Player_Blood = 0;
                Game_Over_On = 1'b1;
            end
        end
    end

    gamestart gamestart_inst(
        .Clk(Clk),
        .Reset(Reset_h),
        .keycode(keycode),
        .PixelX(PixelX),
        .PixelY(PixelY),
        // Output
        .Game_Start_On(Game_Start_On),
        .is_obj(is_game_start),
        .Obj_address(game_start_address)
    );

    gamestartROM gamestartROM_inst(
        .Clk(Clk),
        .read_address(game_start_address),
        .data_Out(game_start_index)
    );

    gameover gameover_inst(
        .Clk(Clk),
        .Reset(Reset_h),
        .Game_Over_On(Game_Over_On),
        .PixelX(PixelX),
        .PixelY(PixelY),
        .is_obj(is_game_over),
        .Obj_address(game_over_address)
    );

    gameoverROM gameoverROM_inst(
        .Clk(Clk),
        .read_address(game_over_address),
        .data_Out(game_over_index)
    );

    score score_inst(
        .Clk(Clk),
        .Total_Score(Total_Score),
        .PixelX(PixelX),
        .PixelY(PixelY),
        .is_obj(is_score),
        .Obj_address(score_address)
    );

    gamelevel game_level_inst(
        .Clk(Clk),
        .Reset(Reset),
        .PixelX(PixelX),
        .PixelY(PixelY),
        .Total_Score(Total_Score),
        .Game_Level(Game_Level),
        .is_obj(is_level),
        .Obj_address(level_address),
        .Enemy_Respawn_Unit_Time(Enemy_Respawn_Unit_Time)
    );

    scoreROM scoreROM_inst(
        .Clk(Clk),
        .read_address0(score_address),
        .data_Out0(score_index),
        .read_address1(level_address),
        .data_Out1(level_index)
    );

    blackboard blackboard_inst(
        .Clk(Clk),
        .Reset(Reset_h),
        .PixelX(PixelX),
        .PixelY(PixelY),
        .is_obj(is_blackboard),
        .Obj_address(blackboard_address)
    );
    blackboardROM blackboardROM_inst(
        .Clk(Clk),
        .read_address(blackboard_address),
        .data_Out(blackboard_index)
    );
    
    blood blood_inst(
        .Clk(Clk),
        .Player_Blood(Player_Blood),
        .PixelX(PixelX),
        .PixelY(PixelY),
        .Godmode_On(Godmode_On),
        .is_obj(is_blood),
        .Obj_address(blood_address)
    );

    bloodROM bloodROM_inst(
        .Clk(Clk),
        .read_address(blood_address),
        .data_Out(blood_index)
    );

    color_mapper color_mapper_inst(
        .*,
        .Reset(Reset_h),
        .enemy_attack_index(existed_enemy_attack_index),
        .is_enemy_attack(existed_is_enemy_attack)
    );


    godmode godmode_inst(
        .Clk(Clk),
        .Reset(Reset_h),
        .game_frame_clk_rising_edge(game_frame_clk_rising_edge),
        .keycode(keycode),
        // Output
        .Godmode_On(Godmode_On)
    );

    // Display keycode on hex display
    HexDriver hex_inst_0 (keycode[3:0], HEX0);
    HexDriver hex_inst_1 (keycode[7:4], HEX1);
    HexDriver hex_inst_2 (keycode[11:8],HEX2);
    HexDriver hex_inst_3 (keycode[15:12],HEX3);

    HexDriver hex_inst_4 (Player_Blood[3:0], HEX4);
    HexDriver hex_inst_5 (Player_Blood[7:4], HEX5);
    
    HexDriver hex_inst_6 (Total_Score[3:0], HEX6);
    HexDriver hex_inst_7 (Total_Score[7:4], HEX7);
endmodule
