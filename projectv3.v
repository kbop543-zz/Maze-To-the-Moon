`timescale 1ns/1ns
module projectv3 (CLOCK_50, KEY, SW, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
        // The ports below are for the VGA output.  Do not change.
        VGA_CLK,                        //  VGA Clock
        VGA_HS,                         //  VGA H_SYNC
        VGA_VS,                         //  VGA V_SYNC
        VGA_BLANK_N,                        //  VGA BLANK
        VGA_SYNC_N,                     //  VGA SYNC
        VGA_R,                          //  VGA Red[9:0]
        VGA_G,                          //  VGA Green[9:0]
        VGA_B                           //  VGA Blue[9:0]
        );
 
    input CLOCK_50;
    input [8:0] KEY;
    input [2:0] SW;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [27:0] rateCount;
    wire [11:0] hexCount;
	 wire [11:0] moveCount;
	 
    wire reset;
    wire go, start, win;
    wire [4:0] in;
    assign reset = ~SW[0];
    assign start = SW[1];
    assign go = (SW[1]^!KEY[3]^!KEY[2]^!KEY[1]^!KEY[0]); //change back in modelsim
    assign in = {SW[1], !KEY[3], !KEY[2], !KEY[1], !KEY[0]};
   
   
    // Do not change the following outputs
    output          VGA_CLK;                //  VGA Clock
    output          VGA_HS;                 //  VGA H_SYNC
    output          VGA_VS;                 //  VGA V_SYNC
    output          VGA_BLANK_N;                //  VGA BLANK
    output          VGA_SYNC_N;             //  VGA SYNC
    output  [9:0]   VGA_R;                  //  VGA Red[9:0]
    output  [9:0]   VGA_G;                  //  VGA Green[9:0]
    output  [9:0]   VGA_B;                  //  VGA Blue[9:0]
 
    wire drawMaze, drawSun, drawMoon, restart, move;
    wire printed, sunPrinted, moonPrinted, moved;
   
    wire [7:0] x;//, x_test;
    wire [6:0] y;//, y_test;
    wire [2:0] colour_out;
    wire [5:0] state_test;
    wire [7:0] i_test;
    wire [5:0] is_test;
    wire b_test;
    wire sunPlacetest, moonPlacetest;
    wire [7:0] sunPos, moonPos;
   
	/////////////////////////////////
	///////////The Maze//////////////
	/////////////////////////////////
	wire [239:0] maze;
	wire [239:0] mazetemp;
 
	assign maze = {
	16'b1111111111111111,
	16'b1000010001000001,
	16'b1001010111111011,
	16'b1001000100110001,
	16'b1001111100110111,
	16'b1001000001110001,
	16'b1001000001010111,
	16'b1001111101010101,
	16'b1000000101010101,
	16'b1111110101000001,
	16'b1100010101011101,
	16'b1001000001000101,
	16'b1011111111110101,
	16'b1000000000000101,
	16'b1111111111111111
	};
 
///////////////////////////////////
///////////////////////////////////
///////////////////////////////////
 
   
   
   
 
    // Create an Instance of a VGA controller - there can be only one!
    // Define the number of colours as well as the initial background
    // image file (.MIF) for the controller.
    vga_adapter VGA(
            .resetn(reset),
            .clock(CLOCK_50),
            .colour(colour_out),
            .x(x),
            .y(y),
            .plot(1'b1),
            // Signals for the DAC to drive the monitor.
            .VGA_R(VGA_R),
            .VGA_G(VGA_G),
            .VGA_B(VGA_B),
            .VGA_HS(VGA_HS),
            .VGA_VS(VGA_VS),
            .VGA_BLANK(VGA_BLANK_N),
            .VGA_SYNC(VGA_SYNC_N),
            .VGA_CLK(VGA_CLK));
        defparam VGA.RESOLUTION = "160x120";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
        defparam VGA.BACKGROUND_IMAGE = "black.mif";
        
 
    control c0(state_test, CLOCK_50, reset, printed, sunPrinted, moonPrinted, go, win, start, moved,drawMaze, drawSun, drawMoon,restart, move);
    datapath d0(CLOCK_50, reset, drawMaze, drawSun, drawMoon, restart, move, in, maze, mazetemp, x, y, colour_out, printed, sunPrinted, moonPrinted, win, moved, moveCount, sunPos, moonPos, i_test, b_test, is_test, sunPlacetest, moonPlacetest/*, test, i_test, x_test, y_test*/);
   
    RateDivider rd0 (28'h2faf080, !SW[0], start, 1'b1, CLOCK_50, rateCount);
    DisplayCounter dc0 (hexCount, !SW[0], start, rateCount == 1'b0, CLOCK_50);
	 
   
    hex_decoder hd0 (.hex_digit(hexCount[11:8]), .segments(HEX5));
	 hex_decoder hd1 (.hex_digit(hexCount[7:4]), .segments(HEX4));
	 hex_decoder hd2 (.hex_digit(hexCount[3:0]), .segments(HEX3));
	 hex_decoder hd3 (.hex_digit(moveCount[11:8]), .segments(HEX2));
	 hex_decoder hd4 (.hex_digit(moveCount[7:4]), .segments(HEX1));
	 hex_decoder hd5 (.hex_digit(moveCount[3:0]), .segments(HEX0));
endmodule
 
module control(state_test,clk, resetn, printed, sunPrinted, moonPrinted, go, win, start, moved, drawMaze, drawSun, drawMoon, restart, move);
    input clk;
   input resetn;
    input printed, sunPrinted, moonPrinted,go,start,moved, win;
    output reg drawMaze, drawSun, drawMoon, restart, move;
    output [5:0] state_test;
   
   reg [5:0] current_state, next_state;  
     
    assign state_test = current_state;
     
     
     
     //assign state_test = current_state[2:0];
   
    localparam  RESET = 6'd1,
                     DRAW_MAZE = 6'd2,
                     DRAW_SUN = 6'd3,
                     DRAW_MOON = 6'd4,
                    // CHECK_RESTART = 6'd5,
                     INPUT = 6'd5,
                     CHECK_INPUT = 6'd6,
                     INPUT_WAIT = 6'd7,
                     RESTART = 6'd8,
                     MOVE = 6'd9,
                     CHECK_WIN = 6'd10;
   
    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
                    RESET: next_state = DRAW_MAZE; // *
                     DRAW_MAZE: next_state = printed ? DRAW_SUN : DRAW_MAZE;
                     DRAW_SUN: next_state = sunPrinted ? DRAW_MOON : DRAW_SUN;
                     DRAW_MOON: next_state = moonPrinted ? INPUT : DRAW_MOON;
             //CHECK_RESTART: next_state = start ? RESTART : INPUT;
                     INPUT: next_state = go ? CHECK_INPUT : INPUT;
                     CHECK_INPUT: next_state = start ? RESTART : INPUT_WAIT;
                     INPUT_WAIT: next_state = go ? INPUT_WAIT : MOVE;
                     RESTART: next_state = go ? RESTART : DRAW_MAZE;
                     MOVE: next_state = moved ? CHECK_WIN : MOVE; //!moved*MOVE + moved*(start*RESTART + !start*DRAW_MAZE);
                     CHECK_WIN: next_state = win ? RESTART : DRAW_MAZE;
                     
            default: next_state = RESET;
        endcase
    end // state_table
   
   
 
    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
            drawMaze = 1'b0;
            drawSun = 1'b0;
            drawMoon = 1'b0;
         restart = 1'b0;
            move = 1'b0;
 
        case (current_state)
            RESET: begin
                drawMaze = 1'b0;
                drawSun = 1'b0;
                drawMoon = 1'b0;
                restart = 1'b0;
                move = 1'b0;
            end
           
            DRAW_MAZE: begin
                drawMaze = 1'b1;
                restart = 1'b0;
            end
           
            DRAW_SUN: begin
                drawSun = 1'b1;
            end
           
            DRAW_MOON: begin
                drawMoon = 1'b1;
            end
 
            RESTART: begin
               restart = 1'b1;
            end
 
            INPUT: begin
            drawMoon = 1'b0;
         end
 
         INPUT_WAIT: begin
            drawMoon = 1'b0;
         end
 
            CHECK_INPUT: begin
                drawMoon = 1'b0;
            end
 
            MOVE: begin
               move = 1'b1;
           end
           
            CHECK_WIN: begin
                drawMoon = 1'b0;
            end
           
         default: next_state = RESET;
        endcase
    end // enable_signal
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= RESET;
        else
            current_state <= next_state;
    end // state_FFS
endmodule
 
module datapath(clk, reset, drawMaze, drawSun, drawMoon, restart, move,in, maze, mazetemp, x, y, colour_out, printed, sunPrinted, moonPrinted, win, moved, moveCount, sunPos, moonPos, i_test, b_test, is_test, sunPlacetest, moonPlacetest/*, test, i_test, x_test, y_test*/);
 
 
    input clk;
    input reset;
    input drawMaze, drawSun, drawMoon,restart, move;
   
    input [239:0] maze;
    output [7:0] x;
   output [6:0] y;
    output [2:0] colour_out;
    output printed, sunPrinted, moonPrinted, moved, win;
    output sunPlacetest, moonPlacetest;
	 
   
	 output [11:0] moveCount;
    //output reg test;.
 
    //output [7:0] x_test;
    //output [6:0] y_test;
   
    input [4:0] in;
    wire [3:0] xm, ym;
    wire [7:0] xb, xs, xmo;
    wire [6:0] yb, ys, ymo;
    wire nextblock, sunPlaced, moonPlaced;
   
    wire bEnable, sEnable, mEnable;
   
    output [7:0] i_test;
    output [5:0] is_test;
    output b_test;
    output [7:0] sunPos, moonPos;
	 output [239:0] mazetemp;
	 
   
    assign b_test = bEnable;
    assign sunPlacetest = sunPlaced;
    assign moonPlacetest = moonPlaced;
   
    //assign x_test = xm;
    //assign y_test = ym;
   
   
    assign colour_out = bEnable*drawMaze*3'b110 + sEnable*drawSun*3'b110 + mEnable*drawMoon*3'b111;
    assign x = xm*4'b1000 + xb*drawMaze + xs*drawSun + xmo*drawMoon + 5'd16;
    assign y = ym*4'b1000 + yb*drawMaze + ys*drawSun + ymo*drawMoon;
   
    print8 p8(clk, drawMaze, reset, xb, yb, nextblock);
    printmaze pm (clk, reset, nextblock, drawSun, drawMoon, moved, moveCount, restart,in, start, win, move,maze, mazetemp, xm, ym, printed, sunPlaced, moonPlaced, sunPos, moonPos, bEnable, i_test);
    printSun ps (clk, drawSun, sunPlaced, reset, xs, ys, sEnable, sunPrinted, is_test);
    printMoon pmo (clk, drawMoon, moonPlaced, reset, xmo, ymo, mEnable, moonPrinted);
   
    /*.
        else if (in == 6'b001000) //left
             left = 1'b1;
       else if( in == 6'b000100) //up
            up = 1'b1;
       else if (in == 6'b000010)
            down = 1'b1;
        else if( in == 6'0000001)
            right = 1'b1;
        end
*/
endmodule
 
module printmaze (clk, reset, drawMaze, drawSun, drawMoon,moved, moveCount, restart,in, start,win,move, maze, mazetemp, x, y, printed, sunPlaced, moonPlaced, sunPos, moonPos, WriteEn, i_test);
    input clk;
    input drawMaze, drawSun, drawMoon,restart,move;
    input reset;
    input [239:0] maze;
    input [4:0] in;
    output reg [3:0] x;
    output reg [3:0] y;
    output reg printed, sunPlaced, moonPlaced;
    output reg WriteEn;
    output reg [7:0] i_test;
   output reg moved;
	output reg win, start;    
	output reg [12:0] moveCount;
	
    output reg [239:0] mazetemp;
	 reg [239:0] mazetemp2;
    reg [8:0] i;
    output reg [7:0] sunPos, moonPos;
	 reg [7:0] sunDetect;
        reg [5:0] counter;
   
         
   
    always @ (posedge clk) begin
        i_test <= counter;
        if (in == 5'b10000) begin
            start <= 1'b1;
            end
 
        if(!reset) begin
            x <= 4'b0000; // Default start 80
            y <= 4'b0000;
            i <= 9'b00000000;
            printed <= 1'b0;
            sunPlaced <= 1'b0;
            moonPlaced <= 1'b0;
            moved <= 1'b0;
				moveCount <= 1'b0;
            WriteEn <= 1'b0;
            mazetemp <= maze;
				mazetemp2 <= maze;
            sunPos <= 8'b0;
            moonPos <= 8'b0;
         counter <= 8'b0;
            win <= 1'b0;
        end
       
        else if(drawMaze) begin
            printed <= 1'b0;
				moved <= 1'b0;
            x <= i[3:0];
            y <= i[7:4];
            if (i == 9'b000000000) begin //if initial not done (first pixel)
                i <= 9'b100000000;
                mazetemp <= maze << 1'b1;
                WriteEn <= mazetemp[239];
                printed <= 1'b0;
            end
            else if (9'b111110000 > i && i > 9'b011111111) begin // once initial done (pixel 2 to 16)
                i <= i + 1'b1;
                mazetemp <= maze << (i[7:0] + 1'b1);
                WriteEn <= mazetemp[239];
                printed <= 1'b0;
            end
 
            else if (i == 9'b111110000) begin //when i[3:0] > 1111 (6'b101111 is 17)
                i <= 9'b000000000;
                printed <= 1'b1;
                WriteEn <= 1'b0;  
            end
        end
       
        else if (drawSun) begin
		  if (!sunPlaced) begin
        case (counter[2:0])
                6'd0: sunPos <= 8'd18;
                6'd1: sunPos <= 8'd20;
                6'd2: sunPos <= 8'd24;
                6'd3: sunPos <= 8'd34;
                6'd4: sunPos <= 8'd49;
                6'd5: sunPos <= 8'd220;
                6'd6: sunPos <= 8'd81;
                6'd7: sunPos <= 8'd222;
            default: sunPos <= 8'd0;
          endcase
		 end
         // mazetemp <= maze << sunPos;
             x <= sunPos[3:0]; // If there is a wall at moonPos, just go to (0,0),
             y <= sunPos[7:4]; // Otherwise send moon to the x,y of moonPos
          sunPlaced <= 1'b1;
             printed <= 1'b0;
        end
                 
       
        else if (drawMoon) begin
                        //always @(*)
							if (!moonPlaced) begin
                    case (counter[2:0])
                                    6'd0: moonPos <= 8'd138;
                                 6'd1: moonPos <= 8'd140;
                                 6'd2: moonPos <= 8'd22; //8'd154;
                                 6'd3: moonPos <= 8'd217;
                                 6'd4: moonPos <= 8'd220;
                                    6'd5: moonPos <= 8'd24;
                                      6'd6: moonPos <= 8'd53;
                                      6'd7: moonPos <= 8'd18;
                                            default: moonPos <= 8'd0;
                                endcase
						end
                               // mazetemp <= maze << moonPos;
                    x <= moonPos[3:0]; // If there is a wall at moonPos, just go to (0,0),
                    y <= moonPos[7:4]; // Otherwise send moon to the x,y of moonPos
                                moonPlaced <= 1'b1;
                    printed <= 1'b0;
                                end      
               
        else if(restart) begin
                  counter <= counter + 1'b1;
                  sunPlaced <= 1'b0;
                  moonPlaced <= 1'b0;
                  printed <= 1'b0;
                  win <= 1'b0;
						moveCount <= 1'b0;
                end    
                     
        else if(move) begin
                     sunDetect <= sunPos;
                        if(in == 5'b01000 && !moved)  begin //left
									
                            mazetemp2 <= maze << (sunDetect -1'd1);
                                sunPos <= sunPos -!mazetemp2[239];
                                moved <= 1'b1;
										  moveCount <= moveCount + !mazetemp2[239];
                            end
                        else if(in == 5'b00100 && !moved) begin //up
                                mazetemp2 <= maze << (sunDetect - 5'd16);
                                    sunPos <= sunPos - !mazetemp2[239]*5'd16;
                                    moved <= 1'b1;
												moveCount <= moveCount + !mazetemp2[239];
                        end
                        else if(in == 5'b00010 && !moved) begin //down
                                mazetemp2 <= maze << (sunDetect + 5'd16);
                                    sunPos <= sunPos + !mazetemp2[239]*5'd16;
                                    moved <= 1'b1;
												moveCount <= moveCount + !mazetemp2[239];
								end


                        else if(in == 5'b00001 && !moved) begin //right
                                mazetemp2 <= maze << (sunDetect + 1'd1);
                                    sunPos <= sunPos + !mazetemp2[239];
                                    moved <= 1'b1;
												moveCount <= moveCount + !mazetemp2[239];
								end
                 win <= (sunPos == moonPos);
            end
 
    end
endmodule
 
module print8 (clk, enable, reset, x, y, nextblock);
    input clk;
    input enable;
    input reset;
    output reg [7:0] x;
    output reg [6:0] y;
    output reg nextblock;
    reg [7:0] i;
   
    always @ (posedge clk) begin
        if (!reset) begin
            x <= 8'b00000000; // Default start 80
            y <= 7'b0000000;
            i <= 8'b00000000;
            nextblock <= 1'b0;
        end
       
        else if (enable) begin
            x <= i[2:0];
            y <= i[5:3];
            nextblock <= 1'b0;
 
            if (i == 8'b00000000) begin //if initial not done (first pixel)
                i <= 8'b10000000;
            end
            else if (8'b11000000 > i && i > 8'b01111111) begin // once initial done (pixel 2 to 16)
                i <= i + 1'b1;
            end
 
            else if (i > 8'b10111111) begin //when i[3:0] > 1111 (6'b101111 is 17)
                i <= 8'b00000000;
                nextblock <= 1'b1;            
            end
        end
    end
 
endmodule
 
module printSun (clk, drawSun, sunPlaced,  reset, x, y, WriteEn, sunPrinted, is_test);
    input clk;
    input sunPlaced;
    input reset;
    input drawSun;
    output reg [7:0] x;
    output reg [6:0] y;
    output reg sunPrinted;
    output reg WriteEn;
    output reg [5:0] is_test;
   
    wire [63:0] sun;
    reg [63:0] sunTemp;
   
    assign sun = {
    8'b10001010,
    8'b01001010,
    8'b00111100,
    8'b00011000,
    8'b11111111,
    8'b00111100,
    8'b01001010,
    8'b01001010
    };
   
    reg [7:0] i;
   
    always @ (posedge clk) begin
        is_test <= i[5:0];
        if (!reset) begin
            x <= 8'b00000000; // Default start 80
            y <= 7'b0000000;
            i <= 8'b00000000;
            sunPrinted <= 1'b0;
            WriteEn <= 1'b0;
        end
       
        else if (sunPlaced && drawSun) begin
            x <= i[2:0];
            y <= i[5:3];
            sunPrinted <= 1'b0;
 
            if (i == 8'b00000000) begin //if initial not done (first pixel)
                i <= 8'b10000000;
                sunTemp <= sun << 1'b1;
                WriteEn <= sunTemp[63];
            end
            else if (8'b11000001 > i && i > 8'b01111111) begin // once initial done (pixel 2 to 16)
                i <= i + 1'b1;
                sunTemp <= sun << (i[5:0] + 1'b1);
                WriteEn <= sunTemp[63];
               
            end
 
            else if (i == 8'b11000001) begin //when i[3:0] > 1111 (6'b101111 is 17)
                i <= 8'b00000000;
                sunPrinted <= 1'b1;
            end
        end
    end
endmodule
 
module printMoon (clk, drawMoon, moonPlaced, reset, x, y, WriteEn, moonPrinted);
    input clk;
    input moonPlaced, drawMoon;
    input reset;
    output reg [7:0] x;
    output reg [6:0] y;
    output reg moonPrinted;
    output reg WriteEn;
    wire [63:0] moon;
    reg [63:0] moonTemp;
   
    assign moon = {
    8'b00111100,
    8'b01111110,
    8'b01111110,
    8'b01111110,
    8'b01111110,
    8'b01111110,
    8'b01111110,
    8'b00111100
    };
   
    reg [7:0] i;
   
    always @ (posedge clk) begin
        if (!reset) begin
            x <= 8'b00000000; // Default start 80
            y <= 7'b0000000;
            i <= 8'b00000000;
            moonPrinted <= 1'b0;
            WriteEn <= 1'b0;
        end
       
        else if (drawMoon && moonPlaced) begin
            x <= i[2:0];
            y <= i[5:3];
            moonPrinted <= 1'b0;
 
            if (i == 8'b00000000) begin //if initial not done (first pixel)
                i <= 8'b10000000;
                moonTemp <= moon << 1'b1;
                WriteEn <= moonTemp[63];
            end
            else if (8'b11000000 > i && i > 8'b01111111) begin // once initial done (pixel 2 to 16)
                i <= i + 1'b1;
                moonTemp <= moon << (i[5:0] + 1'b1);
                WriteEn <= moonTemp[63];  
               
            end
 
            else if (i > 8'b10111111) begin //when i[3:0] > 1111 (6'b101111 is 17)
                i <= 8'b00000000;
                moonPrinted <= 1'b1;
            end
        end
    end
endmodule
 
module DisplayCounter (q, Clear_b, start, Enable, clock);
    output reg [11:0] q;
    input Clear_b, start;
    input Enable;
    input clock;
   
    always @ (posedge clock) //Triggered every time clock rises
    begin
            if (!Clear_b || start) //when Clear_b is 0
                q <= 11'b0; //q is set to 0
            else if (Enable) // increment q only when Enable is 1
                q <= q + 1'b1;
    end
endmodule
 
module RateDivider (d, Clear_b, start, Enable, clock, q); /*Parload,*/
    output reg [27:0] q;
    input wire [27:0] d;
    input Clear_b, start;
    //input Parload;
    input Enable;
    input clock;
   
    always @ (posedge clock) //Triggered every time clock rises
    begin
            if (!Clear_b || start) //when Clear_b is 0
                q <= 28'b0; //q is set to 0
            //else if (Parload == 1'b1) //Check if parallel load
            //  q <= d; // load d
            else if (q == 28'b0) //
                q <= d; //q reset to 0
            else if (Enable) // decrement q only when Enable is 1
                q <= q - 1;
    end
endmodule
 
module hex_decoder(hex_digit, segments); //works
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;  
            default: segments = 7'h7f;
        endcase		  
endmodule
