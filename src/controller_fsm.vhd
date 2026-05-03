----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

signal f_adv_prev : std_logic := '0';
signal f_Q  : std_logic_vector(3 downto 0) := "0001";
signal f_Q_next  : std_logic_vector(3 downto 0) := "0001";


begin

f_Q_next <= "0001" when ((f_Q = "0001" and i_adv = '0') or 
(f_Q = "1000" and i_adv = '1')) else
	"0010" when ((f_Q = "0010" and i_adv = '0') or 
(f_Q = "0001" and i_adv = '1')) else
	"0100" when ((f_Q = "0100" and i_adv = '0') or 
(f_Q = "0010" and i_adv = '1')) else
	"1000" when ((f_Q = "1000" and i_adv = '0') or 
(f_Q = "0100" and i_adv = '1')) else
    "0001"; 
    
o_cycle <= "0001" when f_Q = "0001" else
            "0010" when f_Q = "0010" else
            "0100" when f_Q = "0100" else
            "1000" when f_Q = "1000" else
            "0001";


    register_proc : process (i_adv, i_reset)
    begin
        if i_reset = '1' then
            f_Q <= "0001";        
             f_adv_prev <= '0';
        elsif (i_adv = '1' and f_adv_prev = '0') then
            f_Q <= f_Q_next;    
            f_adv_prev <= '1';
        elsif (i_adv = '0') then
        f_adv_prev <= '0';
          
        end if;
    end process register_proc;

end FSM;
