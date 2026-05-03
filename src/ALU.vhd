----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

 signal w_addsub : STD_LOGIC_VECTOR (7 downto 0);
 signal w_out : STD_LOGIC_VECTOR (7 downto 0);
  signal w_carry : STD_LOGIC;
     
     component ripple_adder is
        Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
           B : in STD_LOGIC_VECTOR (7 downto 0);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR (7 downto 0);
           Cout : out STD_LOGIC);
        end component ripple_adder;

begin
-- PORT MAPS --------------------
    ripple : ripple_adder
    port map (
    Cin => i_op(0),
    A => i_A,
    B => w_addsub,
    S => w_out,
    Cout => w_carry
    );

w_addsub <= (not i_B) when i_op = "001" else
             i_B;
			

o_result <= (i_A OR i_B) when i_op = "011" else
			(i_A AND i_B) when i_op = "010" else
			  (w_out) when i_op = "001" else
			  (w_out) when i_op = "000" else
			  w_out;

o_flags(0) <= (not(i_op(0) xor i_A(7) xor i_B(7))) and (i_A(7) xor w_out(7)) and ((not i_op(1)));
o_flags(1) <= w_carry and (not i_op(1));
o_flags(3) <= w_out(7);
o_flags(2) <= (not w_out(0) and not w_out(1) and not w_out(2)
and not w_out(3) and not w_out(4) and not w_out(5) and not w_out(6)
and not w_out(7));
end Behavioral;
