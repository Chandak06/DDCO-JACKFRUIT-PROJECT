`include "defs.vh"

module elevator_car #(
    parameter ID = 0,
    parameter STOP_CYCLES = 4
) (
    input clk,
    input rst,
    input [`FLOORS-1:0] requests,
    output reg [2:0] current_floor,
    output reg moving,
    output reg [`FLOORS-1:0] pending,
    output reg [`FLOORS-1:0] serviced
);

    localparam S_IDLE = 0;
    localparam S_MOVING = 1;
    localparam S_STOPPED = 2;

    reg [1:0] state;
    reg [2:0] stop_timer;
    reg [2:0] target;
    
    integer i;
    integer next_target;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pending <= 0;
            current_floor <= 0;
            moving <= 0;
            state <= S_IDLE;
            stop_timer <= 0;
            target <= 0;
            serviced <= 0;
        end else begin
            serviced <= 0;
            case (state)
                S_IDLE: begin
                    moving <= 0;
                    stop_timer <= 0;
                    pending <= pending | requests; 
                    if (pending != 0) begin
                        next_target = -1;
                        for (i = 0; i < `FLOORS; i = i + 1) begin
                            if (pending[i]) begin
                                next_target = i;
                                i = `FLOORS;
                            end
                        end
                        if (next_target != -1) begin
                            target <= next_target;
                            if (current_floor == next_target) begin
                                state <= S_STOPPED;
                                pending[next_target] <= 0;
                            end else begin
                                state <= S_MOVING;
                                moving <= 1;
                            end
                        end
                    end
                end

                S_MOVING: begin
                    moving <= 1;
                    pending <= pending | requests; 
                    if (current_floor < target)
                        current_floor <= current_floor + 1;
                    else if (current_floor > target)
                        current_floor <= current_floor - 1;
                    if (current_floor == target) begin
                        state <= S_STOPPED;
                        moving <= 0;
                        pending[target] <= 0;
                        stop_timer <= 0;
                    end
                end
                
                S_STOPPED: begin
                    moving <= 0;
                    serviced[current_floor] <= 1;
                    if (stop_timer == STOP_CYCLES) begin
                        state <= S_IDLE;
                        stop_timer <= 0;
                    end else begin
                        stop_timer <= stop_timer + 1;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
