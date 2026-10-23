--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.JSON;     use Adi.JSON;
with Test_Support; use Test_Support;

--  What Adi.JSON reads back from text, through the vendored json-ada
procedure JSON_Test is

   function B (Code : Natural) return Character is (Character'Val (Code));

   --  UTF-8 test texts. The second byte of each of the first four is in
   --  16#80# .. 16#9F#, which Latin-1 counts as control characters.
   E_Grave : constant String := B (16#C3#) & B (16#88#);           --  U+00C8
   Euro    : constant String := B (16#E2#) & B (16#82#) & B (16#AC#);
   Em_Dash : constant String := B (16#E2#) & B (16#80#) & B (16#94#);
   Emoji   : constant String :=
     B (16#F0#) & B (16#9F#) & B (16#98#) & B (16#80#);            --  U+1F600
   A_Grave : constant String := B (16#C3#) & B (16#A0#);           --  U+00E0

   --  True if the JSON string literal Literal (without quotes) parses
   --  and its value reads as Expected
   function Reads_As (Literal, Expected : String) return Boolean is
   begin
      declare
         P    : Parsers.Parser := Parsers.Create ("[""" & Literal & """]");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         return Root.Get (1).Value = Expected;
      end;
   exception
      when others =>
         return False;
   end Reads_As;

   --  True if the only key of {"Literal": 1} reads as Expected
   function Key_Reads_As (Literal, Expected : String) return Boolean is
   begin
      declare
         P     : Parsers.Parser := Parsers.Create ("{""" & Literal & """: 1}");
         Root  : constant Types.JSON_Value := P.Parse;
         Found : Boolean := False;
      begin
         for Key of Root loop
            Found := Key.Value = Expected;
         end loop;
         return Found;
      end;
   exception
      when others =>
         return False;
   end Key_Reads_As;

   procedure Test_Raw_UTF_8 is
   begin
      Section ("Raw UTF-8 in strings");

      Assert (Reads_As (A_Grave, A_Grave),
              "U+00E0 reads back unchanged");
      Assert (Reads_As (E_Grave, E_Grave),
              "U+00C8 (second byte 16#88#) reads back unchanged");
      Assert (Reads_As (Euro, Euro),
              "U+20AC (second byte 16#82#) reads back unchanged");
      Assert (Reads_As (Em_Dash, Em_Dash),
              "U+2014 (second byte 16#80#) reads back unchanged");
      Assert (Reads_As (Emoji, Emoji),
              "U+1F600 (four bytes) reads back unchanged");
      Assert (Reads_As ("a" & B (16#7F#) & "b", "a" & B (16#7F#) & "b"),
              "DEL needs no escape and reads back unchanged");
      Assert (Key_Reads_As (Euro, Euro),
              "a key holding U+20AC reads back unchanged");
   end Test_Raw_UTF_8;

begin
   Start_Suite ("Adi.JSON Test Suite");

   Test_Raw_UTF_8;

   Finish;
end JSON_Test;
