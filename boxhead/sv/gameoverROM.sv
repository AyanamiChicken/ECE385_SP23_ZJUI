/*
 * ECE385-HelperTools/PNG-To-Txt
 * Author: Rishi Thakkar
 *
 */

module gameoverROM
(
		input [14:0] read_address,
		input Clk,
		output logic [4:0] data_Out
);

// 253 * 78 = 19734. 2^15 = 32768
// logic [4:0] mem [0:19733];
// 211 * 25 = 5275. 2 ^ 13 = 8192
logic [4:0] mem [0:5274];

initial
begin
    $readmemh("sprite/Game_Over_Yellow.txt", mem, 0);
end


always_ff @ (posedge Clk) begin
	data_Out<= mem[read_address];
end

endmodule