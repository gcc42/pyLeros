-- File: pyleros_exec.vhd
-- Generated by MyHDL 1.0dev
-- Date: Tue Aug 16 19:54:26 2016



package pck_pyleros_exec is

attribute enum_encoding: string;

    type t_enum_alu_op_type_1 is (
    NOP,
    LD,
    AND,
    OR,
    XOR
);

end package pck_pyleros_exec;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

use work.pck_myhdl_10.all;

use work.pck_pyleros_exec.all;

entity pyleros_exec is
    port (
        clk: in std_logic;
        reset: in std_logic;
        pipe_alu_op: in t_enum_alu_op_type_1;
        pipe_imme: in unsigned(15 downto 0);
        pipe_dm_addr: in unsigned(7 downto 0);
        pipe_pc: in unsigned(8 downto 0);
        back_acc: out unsigned(15 downto 0);
        back_dm_data: out unsigned(15 downto 0);
        fwd_accu: out unsigned(15 downto 0);
        pipe_dec_store: in std_logic;
        pyleros_alu_0_dec_add_sub: in std_logic;
        pipe_dec_indls: in std_logic;
        pipe_dec_outp: in std_logic;
        pipe_dec_al_ena: in std_logic;
        pipe_dec_br_op: in std_logic;
        pipe_dec_jal: in std_logic;
        pyleros_alu_0_dec_shr: in std_logic;
        pipe_dec_loadh: in std_logic;
        pipe_dec_sel_imm: in std_logic;
        pipe_dec_ah_ena: in std_logic;
        pipe_dec_inp: in std_logic;
        pyleros_alu_0_dec_log_add: in std_logic
    );
end entity pyleros_exec;
-- The execute module for pyleros. The modules is purely 
-- combinatorial, except for the updating the pipeline 
-- register. The DM is instantied and only accessed
-- in this stage. The main function is to execute the ALU
-- operation, read the data memory, update the accumulator, 
-- and feed back teh results to fedec
-- 
-- Arguments (ports):
--     clk: IN Clock signal
--     reset: IN Async reset signal
--     pipe_dec: IN List of the decode signals, from fedec
--     pipe_imme: IN Immediate value, as taken from the lower bits 
--             of the instruction, from fedec
--     pipe_dm_addr: OUT DM read addr, pipeline register, from fedec
--     pipe_pc: IN the value of PC, pipeline register, from fedec
--     back_acc: OUT Value of the acc to send back to fedec.
--     back_dm_data: OUT The data read from the DM, back to fedec for
--         indls
-- 
-- Parameters:
--     debug: Debugging mode, the processor prints various error messages
--     

architecture MyHDL of pyleros_exec is



signal pre_accu: unsigned(15 downto 0);
signal dm_wr_data: unsigned(15 downto 0);
signal dm_wr_addr: unsigned(7 downto 0);
signal opd: unsigned(15 downto 0);
signal pc_dly: unsigned(8 downto 0);
signal dm_wr_en: std_logic;
signal dm_rd_data: unsigned(15 downto 0);
signal dm_rd_addr: unsigned(7 downto 0);
signal acc: unsigned(15 downto 0);
signal pyleros_alu_0_res_arith: unsigned(15 downto 0);
signal pyleros_alu_0_res_log: unsigned(15 downto 0);
type t_array_pyleros_dm_0_DM is array(0 to 256-1) of unsigned(15 downto 0);
signal pyleros_dm_0_DM: t_array_pyleros_dm_0_DM;

begin





PYLEROS_EXEC_FWD_ACC_SET: process (pipe_dec_al_ena, pipe_dec_ah_ena, pre_accu) is
begin
    if (pipe_dec_ah_ena = '1') then
        back_acc(16-1 downto 8) <= pre_accu(16-1 downto 8);
        fwd_accu(16-1 downto 8) <= pre_accu(16-1 downto 8);
    end if;
    if (pipe_dec_al_ena = '1') then
        back_acc(8-1 downto 0) <= pre_accu(8-1 downto 0);
        fwd_accu(8-1 downto 0) <= pre_accu(8-1 downto 0);
    end if;
end process PYLEROS_EXEC_FWD_ACC_SET;


PYLEROS_EXEC_PYLEROS_ALU_0_ACC_MUX: process (pyleros_alu_0_dec_shr, pyleros_alu_0_res_arith, pipe_alu_op, pyleros_alu_0_res_log, pyleros_alu_0_dec_log_add, acc) is
begin
    if (pyleros_alu_0_dec_log_add = '1') then
        pre_accu <= pyleros_alu_0_res_arith;
    elsif (pyleros_alu_0_dec_shr = '1') then
        pre_accu <= shift_right(acc, 1)(16-1 downto 0);
    elsif (not (pipe_alu_op = NOP)) then
        pre_accu <= pyleros_alu_0_res_log;
    end if;
end process PYLEROS_EXEC_PYLEROS_ALU_0_ACC_MUX;


PYLEROS_EXEC_PYLEROS_ALU_0_OP_ADD_SUB: process (pipe_alu_op, pyleros_alu_0_dec_add_sub, opd, acc) is
begin
    
    if (pyleros_alu_0_dec_add_sub = '0') then
        pyleros_alu_0_res_arith <= (acc + opd)(16-1 downto 0);
        
    else
        pyleros_alu_0_res_arith <= (signed(resize(acc, 17)) - signed(resize(opd, 17)))(16-1 downto 0);
    end if;
    if (pipe_alu_op = LD) then
        pyleros_alu_0_res_log <= opd;
    elsif (pipe_alu_op = AND) then
        pyleros_alu_0_res_log <= (acc and opd);
    elsif (pipe_alu_op = OR) then
        pyleros_alu_0_res_log <= (acc or opd);
    elsif (pipe_alu_op = XOR) then
        pyleros_alu_0_res_log <= (acc xor opd);
    end if;
end process PYLEROS_EXEC_PYLEROS_ALU_0_OP_ADD_SUB;


PYLEROS_EXEC_OPD_MUX: process (dm_rd_data, pipe_imme, pipe_dec_sel_imm) is
begin
    if (pipe_dec_sel_imm = '1') then
        opd <= pipe_imme;
    else
        opd <= dm_rd_data;
    end if;
end process PYLEROS_EXEC_OPD_MUX;


PYLEROS_EXEC_PYLEROS_DM_0_READ_WRITE: process (clk, reset) is
begin
    if (reset = '1') then
        pyleros_dm_0_DM(0) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(1) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(2) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(3) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(4) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(5) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(6) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(7) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(8) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(9) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(10) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(11) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(12) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(13) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(14) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(15) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(16) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(17) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(18) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(19) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(20) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(21) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(22) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(23) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(24) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(25) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(26) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(27) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(28) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(29) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(30) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(31) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(32) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(33) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(34) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(35) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(36) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(37) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(38) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(39) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(40) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(41) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(42) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(43) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(44) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(45) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(46) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(47) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(48) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(49) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(50) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(51) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(52) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(53) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(54) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(55) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(56) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(57) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(58) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(59) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(60) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(61) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(62) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(63) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(64) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(65) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(66) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(67) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(68) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(69) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(70) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(71) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(72) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(73) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(74) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(75) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(76) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(77) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(78) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(79) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(80) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(81) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(82) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(83) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(84) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(85) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(86) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(87) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(88) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(89) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(90) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(91) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(92) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(93) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(94) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(95) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(96) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(97) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(98) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(99) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(100) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(101) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(102) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(103) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(104) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(105) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(106) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(107) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(108) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(109) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(110) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(111) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(112) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(113) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(114) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(115) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(116) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(117) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(118) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(119) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(120) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(121) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(122) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(123) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(124) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(125) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(126) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(127) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(128) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(129) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(130) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(131) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(132) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(133) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(134) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(135) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(136) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(137) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(138) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(139) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(140) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(141) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(142) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(143) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(144) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(145) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(146) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(147) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(148) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(149) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(150) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(151) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(152) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(153) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(154) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(155) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(156) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(157) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(158) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(159) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(160) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(161) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(162) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(163) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(164) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(165) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(166) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(167) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(168) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(169) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(170) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(171) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(172) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(173) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(174) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(175) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(176) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(177) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(178) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(179) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(180) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(181) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(182) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(183) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(184) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(185) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(186) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(187) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(188) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(189) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(190) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(191) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(192) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(193) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(194) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(195) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(196) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(197) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(198) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(199) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(200) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(201) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(202) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(203) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(204) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(205) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(206) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(207) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(208) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(209) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(210) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(211) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(212) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(213) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(214) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(215) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(216) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(217) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(218) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(219) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(220) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(221) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(222) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(223) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(224) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(225) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(226) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(227) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(228) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(229) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(230) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(231) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(232) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(233) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(234) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(235) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(236) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(237) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(238) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(239) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(240) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(241) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(242) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(243) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(244) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(245) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(246) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(247) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(248) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(249) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(250) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(251) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(252) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(253) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(254) <= to_unsigned(0000, 16);
        pyleros_dm_0_DM(255) <= to_unsigned(0000, 16);
        dm_rd_data <= to_unsigned(0000, 16);
    elsif falling_edge(clk) then
        
        dm_rd_data <= pyleros_dm_0_DM(to_integer(dm_rd_addr));
        if bool(dm_wr_en) then
            
            pyleros_dm_0_DM(to_integer(dm_wr_addr)) <= dm_wr_data;
        end if;
    end if;
end process PYLEROS_EXEC_PYLEROS_DM_0_READ_WRITE;


PYLEROS_EXEC_MUX_WRITE_DM: process (pipe_dm_addr, pipe_dec_jal, pc_dly, acc, pipe_dec_store) is
begin
    if (pipe_dec_store = '1') then
        dm_wr_en <= '1';
    else
        dm_wr_en <= '0';
    end if;
    dm_wr_addr <= pipe_dm_addr;
    if (pipe_dec_jal = '1') then
        dm_wr_data <= to_unsigned(0, 16);
        dm_wr_data(9-1 downto 0) <= pc_dly;
    else
        dm_wr_data <= acc;
    end if;
end process PYLEROS_EXEC_MUX_WRITE_DM;


PYLEROS_EXEC_SEQ_SET_SIG: process (clk, reset) is
begin
    if (reset = '1') then
        acc <= to_unsigned(0000, 16);
    elsif rising_edge(clk) then
        acc <= acc;
        if (pipe_dec_ah_ena = '1') then
            acc(16-1 downto 8) <= pre_accu(16-1 downto 8);
        end if;
        if (pipe_dec_al_ena = '1') then
            acc(8-1 downto 0) <= pre_accu(8-1 downto 0);
            
        end if;
    end if;
end process PYLEROS_EXEC_SEQ_SET_SIG;



back_dm_data <= dm_rd_data;
dm_rd_addr <= pipe_dm_addr;



pc_dly <= pipe_pc;

end architecture MyHDL;
