module animation(
        CLOCK_50,
        reset,
        go,
        // The ports below are for the VGA output.  Do not change.
  		VGA_CLK,   						//	VGA Clock
  		VGA_HS,							//	VGA H_SYNC
  		VGA_VS,							//	VGA V_SYNC
  		VGA_BLANK_N,					//	VGA BLANK
  		VGA_SYNC_N,						//	VGA SYNC
  		VGA_R,   						//	VGA Red[9:0]
  		VGA_G,	 						//	VGA Green[9:0]
  		VGA_B   						//	VGA Blue[9:0]
  );

      input CLOCK_50;
      input reset;
      input go,
      // Declare your inputs and outputs here
      // Do not change the following outputs
      output		VGA_CLK;   				//	VGA Clock
      output		VGA_HS;					//	VGA H_SYNC
      output		VGA_VS;					//	VGA V_SYNC
      output		VGA_BLANK_N;			//	VGA BLANK
      output		VGA_SYNC_N;				//	VGA SYNC
      output	    [9:0]	VGA_R;   		//	VGA Red[9:0]
      output	    [9:0]	VGA_G;	 		//	VGA Green[9:0]
      output	    [9:0]	VGA_B;   		//	VGA Blue[9:0]

      wire [7:0] x;
      wire [6:0] y;
      wire erase_e;

      frame	f0(
        .CLOCK_50(CLOCK_50),						//	On Board 50 MHz
        // Your inputs and outputs here
        .reset(reset),
        .go(go),
        .erase(erase_e),
        // Where this image is to be drawn
        .x_v(x),
        .y_v(y),
        // The ports below are for the VGA output.  Do not change.
        .VGA_CLK(VGA_CLK),   						//	VGA Clock
        .VGA_HS(VGA_HS),							//	VGA H_SYNC
        .VGA_VS(VGA_VS),							//	VGA V_SYNC
        .VGA_BLANK_N(VGA_BLANK_N),					//	VGA BLANK
        .VGA_SYNC_N(VGA_SYNC_N),					//	VGA SYNC
        .VGA_R(VGA_R),   						    //	VGA Red[9:0]
        .VGA_G(VGA_G),	 						    //	VGA Green[9:0]
        .VGA_B(VGA_B);   						    //	VGA Blue[9:0]

    // The feedback wire between datapath and control,
    // dictate if we finished the drawing process.
    wire d, doe, dod;

    datapath d0(clock, resetn, plot, doe, dod, x, y, erase_e, d);

    control c0(clock, resetn, d, doe, dod);

  );

endmodule

module datapath(clk, resetn, plot, do_e, do_d, x_v, y_v, erase, d);
    input clk, resetn, plot;
    input do_e, do_d;
    output [7:0] x_v;
    output [6:0] y_v;
    output reg erase;
    output reg d;

    // This datapath should be providing frame module with the location of
    // the whole image.
    // x(changing) --> through counterx
    // y(constant).
    wire [7:0] x;
    wire [6:0] y;

    // Instantiate a randomdize module to get the y
    // y = random();
    // assign y_v = y;

    wire move;
    slowcounter s0(enable, clk, reset, move);

    // Start moving.
    // Shifter start
    always @(posedge clk) begin
        // Reset block
        if (!resetn) begin
            x <- 7'd160;
        end
        // Function block
        else begin
            // Begin moving
            if (move) begin
                // Erase the frame if the image hit the left
                if (x - 1 == 7'd0) begin
                    erase <- 1'b1;
                    d <- 1'b0;
                end
                // Move the image if we want to move it:
                //     step 1: Erase the old image
                //     setp 2: Draw a new image
                else begin
                    // step 1
                    if (do_e == 1'b1) begin
                        erase <- 1'b1;
                    end
                    // step 2
                    if (do_d == 1'b1) begin
                        x <- x - 1'b1;
                        d <- 1'b1;
                    end
                end
            end
        end
    end

    assign x_v = x;
    assign y_v = y;

endmodule


module control(clock, reset_n, d, do_e, do_d);
    input clock, reset_n, d;
    output do_e, do_d;

    reg [3:0] current_state, next_state;

    localparam  S_CYCLE_WAIT = 2'd0;
                S_CYCLE_E = 2'd1;
                S_CYCLE_D = 2'd2;

    always@(*)
    begin: state_table
          case (current_state)
              S_CYCLE_WAIT: next_state = (d) ? S_CYCLE_E : S_CYCLE_WAIT;
              S_CYCLE_E: next_state = S_CYCLE_D;
              S_CYCLE_D: next_state = S_CYCLE_WAIT;
          default: next_state = S_CYCLE_WAIT;
          endcase
      end

    always@(*)
    begin: enable_signals
    // By default make all our signals 0
        do_e = 1'b0;
        do_d = 1'b0;

        case(current_state)
            S_CYCLE_WAIT:begin
            // Wait till we want to start the animation
            end
            S_CYCLE_E:begin
            // The drawing process: Erase the old image
            do_e = 1'b1;
            end
            S_CYCLE_D:begin
            // The drawing process: Draw the new image
            do_d = 1'b1;
            end
        endcase
    end

    always@(posedge clock)
    begin: state_FFs
      if(!reset_n)
          current_state <= S_LOAD_X;
      else
          current_state <= next_state;
    end

endmodule


module slowcounter(enable, clk, reset, go);
  input enable, clk, reset;
  output go;

  wire [5:0] q;
  // 833,333 hz --> 1/60 second
  ratedivider(enable, 20'11001011011100110101, clk, reset, q);
  go = (q == 6'd0) ? 1 : 0;

endmodule


module ratedivider(enable, load, clk, reset, q);
	input enable, clk, reset;
	input [5:0] load;
	output reg [5:0] q;

	initial q = load;

	always @(posedge clk)
	begin
		if (reset)
			q <= load;
		else if (enable)
			begin
				if (q == 0)
					q <= load;
				else
					q <= q - 1'b1;
			end
	end
endmodule
