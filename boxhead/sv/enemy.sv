

/*  Enemy
*/

module  enemy #(parameter id) ( input       Clk,                // 50 MHz clock
                             Reset,              // Active-high reset signal
                             game_frame_clk_rising_edge,
               input [7:0]   keycode,
               input [8:0]   PixelX, PixelY,     
               input [8:0]   Player_X, Player_Y,
               input         Enemy_Is_Attacked,
               input  logic  is_alive,
               output logic  is_obj,             // Whether current pixel belongs to ball or background
               output logic [12:0] Obj_address,
               output logic [8:0] Obj_X_Pos, Obj_Y_Pos,
               output logic Enemy_Attack_Ready
              );
    
    // parameter [8:0] Obj_X_Center = 10'd100;  // Center position on the X axis
    // parameter [8:0] Obj_Y_Center = 10'd60;  // Center position on the Y axis
    parameter [8:0] Obj_X_Center = 10'd70 * (id + 1);
    parameter [8:0] Obj_Y_Center = 10'd40 * (id + 1);


    parameter [8:0] Height = 10'd26;         // Height of object
    parameter [8:0] Width = 10'd26;          // Width of object
    parameter [8:0] Player_Height = 10'd20;
    parameter [8:0] Player_Width = 10'd18;

    parameter [8:0] Obj_X_Min = 10'd0;       // Leftmost point on the X axis
    parameter [8:0] Obj_X_Max = 10'd319;     // Rightmost point on the X axis
    parameter [8:0] Obj_Y_Min = 10'd52;       // Topmost point on the Y axis
    parameter [8:0] Obj_Y_Max = 10'd205;     // Bottommost point on the Y axis
    parameter [8:0] Obj_X_Step = 10'd2;      // Step size on the X axis
    parameter [8:0] Obj_Y_Step = 10'd2;      // Step size on the Y axis

    
    logic [8:0] Obj_X_Motion, Obj_Y_Motion; // Current position, left upper point of object
    logic [8:0] Obj_X_Pos_in, Obj_X_Motion_in, Obj_Y_Pos_in, Obj_Y_Motion_in; // Next position
    logic [1:0] Obj_Direction_in, Obj_Direction;
    logic Enemy_Attack_Ready_in;

    // Count how many steps object has walked in one direction
    logic [1:0] Obj_Step_Count;

    // Update registers
    always_ff @ (posedge Clk)
    begin
        if (Reset)
        begin
            // CenterX - Width / 2. CenterY - Height / 2
            Obj_X_Pos <= Obj_X_Center - Width[8:1];
            Obj_Y_Pos <= Obj_Y_Center - Height[8:1];
            Obj_X_Motion <= 10'd0;
            Obj_Y_Motion <= 10'd0;
            Obj_Direction <= 2'd0;
            Enemy_Attack_Ready <= 1'b0;
        end
        else
        begin
            Obj_X_Pos <= Obj_X_Pos_in;
            Obj_Y_Pos <= Obj_Y_Pos_in;
            Obj_X_Motion <= Obj_X_Motion_in;
            Obj_Y_Motion <= Obj_Y_Motion_in;
            Obj_Direction <= Obj_Direction_in;
            Enemy_Attack_Ready <= Enemy_Attack_Ready_in;
        end
    end
    
    // Movement change of the object based on keycode
    always_comb
    begin
        // By default position, direction unchanged and no motion
        // This happens when overlap with player
        Obj_X_Pos_in = Obj_X_Pos;
        Obj_Y_Pos_in = Obj_Y_Pos;
        Obj_X_Motion_in = 10'd0;
        Obj_Y_Motion_in = 10'd0;
        Obj_Direction_in = Obj_Direction;
        Enemy_Attack_Ready_in = Enemy_Attack_Ready;

        if (~is_alive)
            Enemy_Attack_Ready_in = 1'b0;
        
        // Update position and motion only at rising edge of frame clock
        // Dead enemy stays at the same place
        if (game_frame_clk_rising_edge & is_alive)
        begin

            // Fall back when attacked
            if (Enemy_Is_Attacked) begin
                case (Obj_Direction)
                    // Front (Down)
                    2'd0: begin
                        Obj_Y_Motion_in = (~(Obj_Y_Step + 1'b1) + 1'b1);
                    end
                    // Left
                    2'd1: begin
                        Obj_X_Motion_in = Obj_X_Step + 1'b1;
                    end
                    // Back (up)
                    2'd2: begin
                        Obj_Y_Motion_in = Obj_Y_Step + 1'b1;

                    end
                    // Right
                    2'd3: begin
                        Obj_X_Motion_in = (~(Obj_X_Step + 1'b1) + 1'b1);
                    end
                endcase
            end
            // Walk Right
            // If is at left of player and last step is vertical
            else if ((Obj_X_Pos + Width < Player_X)) begin
                Obj_X_Motion_in = Obj_X_Step;
                Obj_Y_Motion_in = 1'b0;
                Obj_Direction_in = 2'd3;

                if (Obj_X_Pos + Width >= Obj_X_Max)
                    Obj_X_Motion_in = 1'b0;
            end
            // Walk Left
            else if ((Obj_X_Pos > Player_X + Player_Width)) begin
                Obj_X_Motion_in = (~(Obj_X_Step) + 1'b1);
                Obj_Y_Motion_in = 1'b0;
                Obj_Direction_in = 2'd1;

                if (Obj_X_Pos <= Obj_X_Min)
                    Obj_X_Motion_in = 1'b0;
            end
            // Walk Down
            else if (Obj_Y_Pos + Height < Player_Y) begin
                Obj_X_Motion_in = 1'b0;
                Obj_Y_Motion_in = Obj_Y_Step;
                Obj_Direction_in = 2'd0;
                    
                if (Obj_Y_Pos + Height >= Obj_Y_Max)
                    Obj_Y_Motion_in = 10'b0;
            end
            // Walk Up
            else if (Obj_Y_Pos > Player_Y + Player_Width) begin
                Obj_X_Motion_in = 1'b0;
                Obj_Y_Motion_in = (~(Obj_Y_Step) + 1'b1);
                Obj_Direction_in = 2'd2;
                if (Obj_Y_Pos <= Obj_Y_Min)
                    Obj_Y_Motion_in = 10'b0;
            end

            // Update the ball's position with its motion, immediate change, use Motion_in instead of Motion
            Obj_X_Pos_in = Obj_X_Pos + Obj_X_Motion_in;
            Obj_Y_Pos_in = Obj_Y_Pos + Obj_Y_Motion_in;

            if ((Obj_X_Motion_in == 0) && (Obj_Y_Motion_in == 0) && (~Enemy_Is_Attacked)) 
                Enemy_Attack_Ready_in = 1'b1;
            else
                Enemy_Attack_Ready_in = 1'b0;
        end
    end

    enemy_control enemy_control_inst(
        // Input
        .*,
        .frame_clk(game_frame_clk_rising_edge),
        .Reset(Reset),
        .Obj_X_Motion(Obj_X_Motion_in),
        .Obj_Y_Motion(Obj_Y_Motion_in),
        // Output
        .Obj_Step_Count(Obj_Step_Count)
    );

    int DistX, DistY;
    assign DistX = PixelX - Obj_X_Pos;
    assign DistY = PixelY - Obj_Y_Pos;
    always_comb begin
        if ((PixelX >= Obj_X_Pos) && (PixelX < (Obj_X_Pos + Width)) &&
            (PixelY >= Obj_Y_Pos) && (PixelY < (Obj_Y_Pos + Height)) && (is_alive)) begin
            is_obj = 1'b1;

            // Compute Object address based on its position, direction and walk step count
            if (~Obj_Step_Count[0])
                Obj_address = DistX + DistY * Width + Width * Height * (3 * Obj_Direction);
            else
                Obj_address = DistX + DistY * Width + Width * Height * (3 * Obj_Direction + 1 + Obj_Step_Count[1]);
        end
        else begin
            is_obj = 1'b0;
            Obj_address = 11'b0;
        end
    end


    
endmodule
