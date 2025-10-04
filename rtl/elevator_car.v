`include "rtl/defs.vh"

module elevator_car #(
    parameter ID = 0
) (
    input clk,
    input rst,
    input [`FLOORS-1:0] requests, // bitmask of floors requested for this car
    output reg [`FLOORS-1:0] pending, // internal pending mask
    output reg [2:0] current_floor, // enough bits for floors
    output reg moving // 1 if moving, 0 if idle
);

    // Simple model: on request set pending; move towards lowest-index set bit
    integer i;
    integer target;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pending <= 0;
            current_floor <= 0;
            moving <= 0;
        end else begin
            // add new requests
            pending <= pending | requests;

            if (pending == 0) begin
                moving <= 0;
            end else begin
                moving <= 1;
                // find lowest-index set bit
                target = -1;
                for (i=0;i<`FLOORS;i=i+1) begin
                    if (pending[i]) begin
                        target = i;
                        i = `FLOORS; // exit loop
                    end
                end

                if (target != -1) begin
                    if (current_floor < target)
                        current_floor <= current_floor + 1;
                    else if (current_floor > target)
                        current_floor <= current_floor - 1;
                    else
                        pending[target] <= 0; // arrived, clear
                end
            end
        end
    end

endmodule
