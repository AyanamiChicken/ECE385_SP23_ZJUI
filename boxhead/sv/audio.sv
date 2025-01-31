//-------------------------------------------------------------------------
//      audio.sv                                                         --
//      Created by Yihong Jin                                            --
//      Cited by Jiadong Hong (2023.5.16)                                --
//      Fall 2021                                                        --
//                                                                       --
//      This module helps to control the sound play of the board         --
//      UIUC ECE Department                                              --
//-------------------------------------------------------------------------


module audio (   
	input logic Clk, Reset, 
	input logic INIT_FINISH,
	input logic data_over,
	input logic [16:0] music_frequency,
	output logic INIT_BGM,
	output [16:0] Add
);

logic [15:0] counter;
logic [15:0] inner_counter;
enum logic {WAIT,RUN} current_state, next_state;
logic [16:0] inner_Add;
logic [16:0] num;
assign num = 17'd80549;

always_ff @ (posedge Clk)
	begin
		if (Reset)
		begin
			current_state <= WAIT;
			counter <= 16'd0;
			Add <= 17'd0;
		end
		else
		begin
			current_state <= next_state;
			counter <= inner_counter;
			Add <= inner_Add;
		end
	end
		
always_comb
	begin
		unique case(current_state)
			WAIT:
				begin
					if (INIT_FINISH == 4'd01)
						begin
							next_state = RUN;
							INIT_BGM = 1'd01;
						end
					else
						begin
							next_state = WAIT;
							
						end
					INIT_BGM = 1'd01;	
					inner_counter = 16'd0;
					inner_Add = 17'd0;
				end

				
			
			RUN:
			begin 
				next_state = RUN;
				INIT_BGM = 1'd01;
				
				if (counter< music_frequency+1 )
					inner_counter = counter+16'd1;
				else
					inner_counter = 16'd0;
					
				if (counter== music_frequency && Add <= num && data_over!=0)
					inner_Add = Add+17'd1;
				else if (Add < num)
					inner_Add = Add;
				else
					inner_Add = 17'd0;
			end	
		
		default: ;
		endcase	
	end

endmodule


