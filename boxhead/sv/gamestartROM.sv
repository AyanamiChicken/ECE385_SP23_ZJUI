/*
 * ECE385-HelperTools/PNG-To-Txt
 * Author: Rishi Thakkar
 *
 */

module gamestartROM
(
		input [14:0] read_address,
		input Clk,
		output logic [4:0] data_Out
);

// 297 * 89 = 26433. 2 ^ 15 = 32768
// logic [4:0] mem [0:26432];
// 180 * 24 = 4320. 2 ^ 13 = 8192
logic [4:0] mem [0:4319];

initial
begin
    $readmemh("sprite/Title_Yellow.txt", mem, 0);
end


always_ff @ (posedge Clk) begin
	data_Out<= mem[read_address];
end

endmodule