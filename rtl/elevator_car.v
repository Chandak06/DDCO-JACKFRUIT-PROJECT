`include "rtl/defs.vh"

module elevator_car #(
    parameter ID = 0,
    parameter STOP_CYCLES = 4 // How long to wait at a floor
) (
    input clk,
    input rst,
    input [`FLOORS-1:0] requests, // bitmask of floors requested for this car
    output reg [2:0] current_floor, // enough bits for floors
    output reg moving, // 1 if moving, 0 if idle
    // expose pending requests so controller can inspect/monitor (controller instantiation may use .pending())
    output reg [`FLOORS-1:0] pending,
    // one-hot mask indicating which floor is being serviced this cycle
    output reg [`FLOORS-1:0] serviced
);

    // FSM States
    localparam S_IDLE = 0;
    localparam S_MOVING = 1;
    localparam S_STOPPED = 2; // "Door open" state

    reg [1:0] state;
    reg [2:0] stop_timer; // Timer for S_STOPPED state
    // `pending` is declared as an output port and used internally as the pending mask
    reg [2:0] target; // Target floor
    
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
            // default: no floor is being serviced this cycle
            serviced <= 0;
            case (state)
                S_IDLE: begin
                    moving <= 0;
                    stop_timer <= 0;
                    
                    // Latch in new requests *only* when idle
                    pending <= pending | requests; 

                    if (pending != 0) begin
                        // Find lowest-index set bit (original logic)
                        next_target = -1;
                        for (i=0; i<`FLOORS; i=i+1) begin
                            if (pending[i]) begin
                                next_target = i;
                                i = `FLOORS; // exit loop
                            end
                        end

                        if (next_target != -1) begin
                            target <= next_target;
                            if (current_floor == next_target) begin
                                // Already at the target floor
                                state <= S_STOPPED;
                                pending[next_target] <= 0; // Clear request
                            end else begin
                                state <= S_MOVING;
                                moving <= 1;
                            end
                        end
                        // else: pending != 0 but no target? stay idle.
                    end
                    // else: pending == 0, just stay in IDLE
                end

                S_MOVING: begin
                    moving <= 1;
                    
                    // Latch new requests while moving
                    pending <= pending | requests; 

                    if (current_floor < target)
                        current_floor <= current_floor + 1;
                    else if (current_floor > target)
                        current_floor <= current_floor - 1;
                    
                    // Check for arrival (at next posedge, floor will be updated)
                    if (current_floor == target) begin
                        state <= S_STOPPED;
                        moving <= 0; // Stop motor
                        pending[target] <= 0; // Clear the request
                        stop_timer <= 0;
                    end
                end
                
                S_STOPPED: begin
                    moving <= 0;
                    serviced[current_floor] <= 1; // indicate which floor is being serviced

                    // We already cleared the request when entering this state
                    // DO NOT latch new requests here, wait until IDLE

                    if (stop_timer == STOP_CYCLES) begin
                        state <= S_IDLE; // Go back to IDLE to find new target
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
