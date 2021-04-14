// Please include verilog file if you write module in other file

`define RTYPE 7'b0110011  //R-type
`define ITYPE 7'b0010011  //I-type
`define LWTYPE 7'b0000011 //I-type lw lb lh lbu lhu
`define JALR 7'b1100111   //I-type jalr
`define STYPE 7'b0100011  //S-type
`define BTYPE 7'b1100011  //B-type
`define AUIPC 7'b0010111  //U-type AUIPC
`define LUI 7'b0110111    //U-type LUI
`define JTYPE 7'b1101111  //J-type

module CPU(
    input             clk,        //cpu clock
    input             rst,        //reset signal
    input      [31:0] data_out,   //get data from DM when data_read = 1
    input      [31:0] instr_out,  //get data from IM when instr_read = 1
    output reg        instr_read, //decide whether read instruction or not
    output reg        data_read,  //decide whether read data or not 
    output reg [31:0] instr_addr, //address of instruction (to decide which instr to take)
    output reg [31:0] data_addr,  //the data which will be wrote into DM.
    output reg [3:0]  data_write, //4bit control, decide whether write to DM every 8bit (SW, SH, SB)
    output reg [31:0] data_in     //data going to write to DM. 
);

reg [4:0]  rs1_addr = 5'b0;  //rs1
reg [4:0]  rs2_addr = 5'b0;  //rs2
reg [31:0] rd       = 32'b0; //rd
reg [6:0]  funct7   = 7'b0;
reg [2:0]  funct3   = 3'b0;
reg [31:0] imm      = 32'b0; //local register
reg [31:0] lrst[31:0];
reg [31:0] temp     = 32'b0;
reg [31:0] delay    = 32'b0;
reg [1:0]  ldelay   = 2'd0;

/* Add your design */

initial 
begin
	instr_read=1;
	instr_addr=0;
	data_read=0;
	data_write=0;
	data_addr=0;
end

always @(posedge clk)
begin
	data_write = 0;
	lrst[0] = 0;
	if(rst == 1)
	begin
		instr_read = 1;
	end
	else
	begin
		if(delay!=1)
		begin
			delay = delay + 1;
		end
		else
		begin
		case(instr_out[6:0])
		//R-Type////////////////////////////////////////////////
		`RTYPE: 
		begin
			funct7 = instr_out[31:25];
			rs2_addr = instr_out[24:20];
			rs1_addr = instr_out[19:15];
			funct3 = instr_out[14:12];
			rd = instr_out[11:7];
			
			if(funct7 == 7'b0000000)
			begin
				case(funct3)
				3'b000:begin lrst[rd] = lrst[rs1_addr] + lrst[rs2_addr]; end //ADD
				3'b001:begin lrst[rd] = $unsigned(lrst[rs1_addr]) << lrst[rs2_addr][4:0]; end //SLL
				3'b010:begin lrst[rd] = $signed(lrst[rs1_addr]) < $signed(lrst[rs2_addr]) ? 1 : 0; end //SLT
				3'b011:begin lrst[rd] = $unsigned(lrst[rs1_addr]) < $unsigned(lrst[rs2_addr]) ? 1 : 0; end //SLTU
				3'b100:begin lrst[rd] = lrst[rs1_addr] ^ lrst[rs2_addr]; end //XOR
				3'b101:begin lrst[rd] = $unsigned(lrst[rs1_addr]) >> $unsigned(lrst[rs2_addr][4:0]); end //SRL
				3'b110:begin lrst[rd] = lrst[rs1_addr] | lrst[rs2_addr]; end //OR
				3'b111:begin lrst[rd] = lrst[rs1_addr] & lrst[rs2_addr]; end //AND
				endcase
			end
			else
			begin
				if(funct3 == 3'b000) lrst[rd] = lrst[rs1_addr] - lrst[rs2_addr]; //SUB
				else lrst[rd] = lrst[rs1_addr] >> lrst[rs2_addr][4:0]; //SRA
			end
			instr_addr = instr_addr + 32'b0100;
		end
		
		//I-type////////////////////////////////////////////////
		`LWTYPE, `ITYPE, `JALR: 
		begin
			imm[11:0] = instr_out[31:20];
			if(imm[11] == 0) imm[31:12] = 20'b00000000000000000000;
			else imm[31:12] = 20'b11111111111111111111;
			rs1_addr = instr_out[19:15];
			funct3 = instr_out[14:12];
			rd = instr_out[11:7];
			
			if(instr_out[6:0] == `LWTYPE) //lw lb lh lbu lhu
			begin
				if(delay!=1)
				begin
					delay = delay + 1;
				end
				else
				begin
					instr_read = 0;
					data_read = 1;
					data_addr = lrst[rs1_addr] + imm;
					ldelay = 2'd1;
					delay = 32'b0;
				end
			end
			else if(instr_out[6:0] == `ITYPE)
			begin		
				case(funct3)
					3'b000:begin lrst[rd] = lrst[rs1_addr] + imm;end //ADDI
					3'b010:begin lrst[rd] = $signed(lrst[rs1_addr]) < $signed(imm) ? 1 : 0;end //SLTI
					3'b011:begin lrst[rd] = $unsigned(lrst[rs1_addr]) < $unsigned(imm) ? 1 : 0;end //SLTIU
					3'b100:begin lrst[rd] = lrst[rs1_addr] ^ imm;end //XORI
					3'b110:begin lrst[rd] = lrst[rs1_addr] | imm;end //ORI
					3'b111:begin lrst[rd] = lrst[rs1_addr] & imm;end //ANDI
					3'b001:begin lrst[rd] = $unsigned(lrst[rs1_addr]) << imm[4:0];end //SLLI		
					3'b101:
					begin
						if(imm[11:5] == 7'b0000000)lrst[rd] = $unsigned(lrst[rs1_addr]) >> imm[4:0]; //SRLI
						else lrst[rd] = $signed(lrst[rs1_addr]) >>> imm[4:0]; //SRAI
					end
				endcase	
				instr_addr = instr_addr + 32'b0100;		
			end
			//jalr temp
			else begin temp = lrst[rs1_addr];lrst[rd] = instr_addr + 4;instr_addr = imm + temp; end	
		end
		
		//S-type////////////////////////////////////////////////
		`STYPE:
		begin
			imm[11:5] = instr_out[31:25];	
			rs2_addr = instr_out[24:20];
			rs1_addr = instr_out[19:15];	
			funct3 = instr_out[14:12];
			imm[4:0] = instr_out[11:7];

			if(imm[11] == 0) begin imm[31:12] = 20'b00000000000000000000;end
			else begin imm[31:12] = 20'b11111111111111111111; end

			//data_write = 4'b1111;
			data_addr = lrst[rs1_addr] + imm;
			//data_in = lrst[rs2_addr];
            /*****************/
            case(funct3)
                3'b010:begin //sw
                  data_in = lrst[rs2_addr];
                  data_write = 4'b1111;
                end
                3'b000:begin  //sb
                    case(data_addr[1:0])
                        2'b00:begin
                            data_write = 4'b0001;
                            data_in[31:8] = 24'b000000000000000000000000;
                            data_in[7:0] = lrst[rs2_addr][7:0];  
                        end
                        2'b10:begin
                            data_write = 4'b0100;
                            data_in[7:0] = 8'b00000000;
                            data_in[15:8] = lrst[rs2_addr][7:0];
                            data_in[31:16] = 16'b0000000000000000;   
                        end
                        2'b01:begin
                            data_write = 4'b0010;
                            data_in[7:0] = 8'b00000000;
                            data_in[15:8] = lrst[rs2_addr][7:0];
                            data_in[31:16] = 16'b0000000000000000;  
                        end
                        2'b11:begin
                            data_write = 4'b1000;
                            data_in[31:24] = lrst[rs2_addr][7:0];
                            data_in[23:0] = 24'b000000000000000000000000;  
                        end
                    endcase
                  
                end
                3'b001:begin
                    case(data_addr[1:0])
                        2'b00:begin
                            data_write = 4'b0011;
                            data_in[31:16] = 16'b0000000000000000;
                            data_in[15:0] = lrst[rs2_addr][15:0];  
                        end
                        2'b01:begin
                            data_write = 4'b0110;
                            data_addr[31:24] = 18'b000000000000000000;
                            data_in[23:8] = lrst[rs2_addr][15:0];
                            data_in[7:0] = 8'b00000000;  
                        end
                        2'b10:begin
                            data_write = 4'b1100;
                            data_in[31:16] = lrst[rs2_addr][15:0];
                            data_in[15:0] = 16'b0000000000000000;  
                        end
                    endcase  
                end
            endcase
            /*****************/
			instr_addr = instr_addr + 32'b0100;
		end
		
		//B-type////////////////////////////////////////////////
		`BTYPE:
		begin
			imm[12] = instr_out[31];
			imm[10:5] = instr_out[30:25];	
			rs2_addr = instr_out[24:20];
			rs1_addr = instr_out[19:15];	
			funct3 = instr_out[14:12];
			imm[4:1] = instr_out[11:8];
			imm[11] = instr_out[7];
			imm[0] = 0;

			if(imm[12] == 0) 
				imm[31:13] = 19'b0000000000000000000;
			else 
				imm[31:13] = 19'b1111111111111111111;

			case(funct3)
				3'b000:begin instr_addr = (lrst[rs1_addr] == lrst[rs2_addr])? instr_addr  + imm : instr_addr + 32'b0100;end//BEQ
				3'b001:begin instr_addr = (lrst[rs1_addr] != lrst[rs2_addr])? instr_addr  + imm : instr_addr + 32'b0100;end//BNE
				3'b100:begin instr_addr = ($signed(lrst[rs1_addr]) < $signed(lrst[rs2_addr]))? instr_addr  + imm : instr_addr + 32'b0100;end//BLT
				3'b101:begin instr_addr = ($signed(lrst[rs1_addr]) >= $signed(lrst[rs2_addr]))? instr_addr  + imm : instr_addr + 32'b0100;end//BGE
				3'b110:begin instr_addr = ($unsigned(lrst[rs1_addr]) < $unsigned(lrst[rs2_addr]))? instr_addr  + imm : instr_addr + 32'b0100;end//BLTU
				3'b111:begin instr_addr = ($unsigned(lrst[rs1_addr]) >= $unsigned(lrst[rs2_addr]))? instr_addr  + imm : instr_addr + 32'b0100;end//BGEU
			endcase
		end
		
		//U-type////////////////////////////////////////////////
		`AUIPC ,`LUI:
		begin
			imm[31:12] = instr_out[31:12];
			imm[11:0] = 12'b000000000000;
			rd = instr_out[11:7];

			if(instr_out[6:0] ==  `AUIPC) lrst[rd] = instr_addr + imm;//AUIPC
			else lrst[rd] = imm;//LUI
			
			instr_addr = instr_addr + 32'b0100;
		end
		
		//J-type////////////////////////////////////////////////
		`JTYPE:
		begin
			imm[20] = instr_out[31];
			imm[10:1] = instr_out[30:21];
			imm[11] = instr_out[20];
			imm[19:12] = instr_out[19:12];

			if(imm[20] == 0)imm[31:21] = 11'b00000000000;
			else imm[31:21] = 11'b11111111111;

			imm[0] = 0;
			rd = instr_out[11:7];
			lrst[rd] = instr_addr + 32'b0100;
			instr_addr = instr_addr + imm;//JAL
		end
		endcase
		delay = 32'b0;
		end
	end
end


always @(posedge clk)
begin
	if(data_read == 0);
	else 
	begin
		if(ldelay == 2'd1) begin
			ldelay = ldelay + 2'd1;
		end
		else if(ldelay == 2'd2) begin
			ldelay = ldelay + 2'd1;
		end
		else if(ldelay == 2'd3) begin
			ldelay = 2'd0;
			/***************/
        //if(instr_out[6:0] == `LWTYPE)begin
            case(funct3)
                3'b010:begin
					lrst[rd] = data_out;
				end
                3'b000:begin
                  lrst[rd][7:0] = data_out[7:0];
                  if(data_out[7])begin
                    lrst[rd][31:8] = 24'b111111111111111111111111;
                  end
                  else begin
                    lrst[rd][31:8] = 24'b000000000000000000000000;
                  end
                end
                3'b001:begin
                  lrst[rd][15:0] = data_out[15:0];
                  if(data_out[15])begin
                    lrst[rd][31:16] = 16'b1111111111111111;
                  end
                  else begin
                    lrst[rd][31:16] = 16'b0000000000000000;
                  end
                end
                3'b100:begin
                  lrst[rd][7:0] = data_out[7:0];
                  lrst[rd][31:8] = 24'b000000000000000000000000;
                end
                3'b101:begin
                  lrst[rd][15:0] = data_out[15:0];
                  lrst[rd][31:16] = 24'b000000000000000000000000;
                end
            endcase  
        //end
        /***************/

		//lrst[rd] = data_out;
		data_read = 0;
		instr_read = 1;
		instr_addr = instr_addr + 32'b0100;

		end       
	end
end


endmodule
