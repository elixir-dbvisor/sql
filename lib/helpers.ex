# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Helpers do
  @moduledoc false

  defguard is_newline(b) when b in [10, 11, 12, 13, 133, 8232, 8233]
  defguard is_space(b) when b in ~c" "
  defguard is_whitespace(b) when b in [9, 13, 160, 160, 5760, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288, 6158, 8203, 8204, 8205, 8288, 65279]
  defguard is_literal(b) when b == ?" or b == ?' or b == ?`
  defguard is_expr(b) when b in [:paren, :bracket, :brace]
  defguard is_nested_start(b) when b in ~c"([{"
  defguard is_nested_end(b) when b in ~c")]}"
  defguard is_special_character(b) when b in ~c" \"%&'()*+,-./:;<=>?[]^_|{}$@!~#"
  defguard is_digit(b) when b in ~c"0123456789"
  defguard is_comment(b) when b in ["--", "/*"]
  defguard is_sign(b) when b == ?- or b == ?+
  defguard is_dot(b) when b == ?.
  defguard is_delimiter(b) when b == ?; or b == ?,
  
  defguard is_a(b) when b == 97 or b == 65
  
  defguard is_b(b) when b == 98 or b == 66
  
  defguard is_c(b) when b == 99 or b == 67
  
  defguard is_d(b) when b == 100 or b == 68
  
  defguard is_e(b) when b == 101 or b == 69
  
  defguard is_f(b) when b == 102 or b == 70
  
  defguard is_g(b) when b == 103 or b == 71
  
  defguard is_h(b) when b == 104 or b == 72
  
  defguard is_i(b) when b == 105 or b == 73
  
  defguard is_j(b) when b == 106 or b == 74
  
  defguard is_k(b) when b == 107 or b == 75
  
  defguard is_l(b) when b == 108 or b == 76
  
  defguard is_m(b) when b == 109 or b == 77
  
  defguard is_n(b) when b == 110 or b == 78
  
  defguard is_o(b) when b == 111 or b == 79
  
  defguard is_p(b) when b == 112 or b == 80
  
  defguard is_q(b) when b == 113 or b == 81
  
  defguard is_r(b) when b == 114 or b == 82
  
  defguard is_s(b) when b == 115 or b == 83
  
  defguard is_t(b) when b == 116 or b == 84
  
  defguard is_u(b) when b == 117 or b == 85
  
  defguard is_v(b) when b == 118 or b == 86
  
  defguard is_w(b) when b == 119 or b == 87
  
  defguard is_x(b) when b == 120 or b == 88
  
  defguard is_y(b) when b == 121 or b == 89
  
  defguard is_z(b) when b == 122 or b == 90
  

  
  def tag([[[[], b1], b2], b3]) when is_a(b1) and is_b(b2) and is_s(b3), do: {:reserved, :abs}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_a(b1) and is_b(b2) and is_s(b3) and is_e(b4) and is_n(b5) and is_t(b6), do: {:reserved, :absent}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_a(b1) and is_c(b2) and is_o(b3) and is_s(b4), do: {:reserved, :acos}
  
  def tag([[[[], b1], b2], b3]) when is_a(b1) and is_l(b2) and is_l(b3), do: {:reserved, :all}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_a(b1) and is_l(b2) and is_l(b3) and is_o(b4) and is_c(b5) and is_a(b6) and is_t(b7) and is_e(b8), do: {:reserved, :allocate}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_a(b1) and is_l(b2) and is_t(b3) and is_e(b4) and is_r(b5), do: {:reserved, :alter}
  
  def tag([[[[], b1], b2], b3]) when is_a(b1) and is_n(b2) and is_d(b3), do: {:reserved, :and}
  
  def tag([[[[], b1], b2], b3]) when is_a(b1) and is_n(b2) and is_y(b3), do: {:reserved, :any}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_a(b1) and is_n(b2) and is_y(b3) and b4 in ~c"_" and is_v(b5) and is_a(b6) and is_l(b7) and is_u(b8) and is_e(b9), do: {:reserved, :any_value}
  
  def tag([[[[], b1], b2], b3]) when is_a(b1) and is_r(b2) and is_e(b3), do: {:reserved, :are}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_a(b1) and is_r(b2) and is_r(b3) and is_a(b4) and is_y(b5), do: {:reserved, :array}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_a(b1) and is_r(b2) and is_r(b3) and is_a(b4) and is_y(b5) and b6 in ~c"_" and is_a(b7) and is_g(b8) and is_g(b9), do: {:reserved, :array_agg}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21]) when is_a(b1) and is_r(b2) and is_r(b3) and is_a(b4) and is_y(b5) and b6 in ~c"_" and is_m(b7) and is_a(b8) and is_x(b9) and b10 in ~c"_" and is_c(b11) and is_a(b12) and is_r(b13) and is_d(b14) and is_i(b15) and is_n(b16) and is_a(b17) and is_l(b18) and is_i(b19) and is_t(b20) and is_y(b21), do: {:reserved, :array_max_cardinality}
  
  def tag([[[], b1], b2]) when is_a(b1) and is_s(b2), do: {:reserved, :as}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_a(b1) and is_s(b2) and is_e(b3) and is_n(b4) and is_s(b5) and is_i(b6) and is_t(b7) and is_i(b8) and is_v(b9) and is_e(b10), do: {:reserved, :asensitive}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_a(b1) and is_s(b2) and is_i(b3) and is_n(b4), do: {:reserved, :asin}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_a(b1) and is_s(b2) and is_y(b3) and is_m(b4) and is_m(b5) and is_e(b6) and is_t(b7) and is_r(b8) and is_i(b9) and is_c(b10), do: {:reserved, :asymmetric}
  
  def tag([[[], b1], b2]) when is_a(b1) and is_t(b2), do: {:reserved, :at}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_a(b1) and is_t(b2) and is_a(b3) and is_n(b4), do: {:reserved, :atan}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_a(b1) and is_t(b2) and is_o(b3) and is_m(b4) and is_i(b5) and is_c(b6), do: {:reserved, :atomic}
  
  def tag([[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when is_a(b1) and is_u(b2) and is_t(b3) and is_h(b4) and is_o(b5) and is_r(b6) and is_i(b7) and is_z(b8) and is_a(b9) and is_t(b10) and is_i(b11) and is_o(b12) and is_n(b13), do: {:reserved, :authorization}
  
  def tag([[[[], b1], b2], b3]) when is_a(b1) and is_v(b2) and is_g(b3), do: {:reserved, :avg}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_b(b1) and is_e(b2) and is_g(b3) and is_i(b4) and is_n(b5), do: {:reserved, :begin}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_b(b1) and is_e(b2) and is_g(b3) and is_i(b4) and is_n(b5) and b6 in ~c"_" and is_f(b7) and is_r(b8) and is_a(b9) and is_m(b10) and is_e(b11), do: {:reserved, :begin_frame}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_b(b1) and is_e(b2) and is_g(b3) and is_i(b4) and is_n(b5) and b6 in ~c"_" and is_p(b7) and is_a(b8) and is_r(b9) and is_t(b10) and is_i(b11) and is_t(b12) and is_i(b13) and is_o(b14) and is_n(b15), do: {:reserved, :begin_partition}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_b(b1) and is_e(b2) and is_t(b3) and is_w(b4) and is_e(b5) and is_e(b6) and is_n(b7), do: {:reserved, :between}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_b(b1) and is_i(b2) and is_g(b3) and is_i(b4) and is_n(b5) and is_t(b6), do: {:reserved, :bigint}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_b(b1) and is_i(b2) and is_n(b3) and is_a(b4) and is_r(b5) and is_y(b6), do: {:reserved, :binary}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_b(b1) and is_l(b2) and is_o(b3) and is_b(b4), do: {:reserved, :blob}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_b(b1) and is_o(b2) and is_o(b3) and is_l(b4) and is_e(b5) and is_a(b6) and is_n(b7), do: {:reserved, :boolean}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_b(b1) and is_o(b2) and is_t(b3) and is_h(b4), do: {:reserved, :both}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_b(b1) and is_t(b2) and is_r(b3) and is_i(b4) and is_m(b5), do: {:reserved, :btrim}
  
  def tag([[[], b1], b2]) when is_b(b1) and is_y(b2), do: {:reserved, :by}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_c(b1) and is_a(b2) and is_l(b3) and is_l(b4), do: {:reserved, :call}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_c(b1) and is_a(b2) and is_l(b3) and is_l(b4) and is_e(b5) and is_d(b6), do: {:reserved, :called}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_c(b1) and is_a(b2) and is_r(b3) and is_d(b4) and is_i(b5) and is_n(b6) and is_a(b7) and is_l(b8) and is_i(b9) and is_t(b10) and is_y(b11), do: {:reserved, :cardinality}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_c(b1) and is_a(b2) and is_s(b3) and is_c(b4) and is_a(b5) and is_d(b6) and is_e(b7) and is_d(b8), do: {:reserved, :cascaded}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_c(b1) and is_a(b2) and is_s(b3) and is_e(b4), do: {:reserved, :case}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_c(b1) and is_a(b2) and is_s(b3) and is_t(b4), do: {:reserved, :cast}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_c(b1) and is_e(b2) and is_i(b3) and is_l(b4), do: {:reserved, :ceil}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_c(b1) and is_e(b2) and is_i(b3) and is_l(b4) and is_i(b5) and is_n(b6) and is_g(b7), do: {:reserved, :ceiling}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_c(b1) and is_h(b2) and is_a(b3) and is_r(b4), do: {:reserved, :char}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_c(b1) and is_h(b2) and is_a(b3) and is_r(b4) and b5 in ~c"_" and is_l(b6) and is_e(b7) and is_n(b8) and is_g(b9) and is_t(b10) and is_h(b11), do: {:reserved, :char_length}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_c(b1) and is_h(b2) and is_a(b3) and is_r(b4) and is_a(b5) and is_c(b6) and is_t(b7) and is_e(b8) and is_r(b9), do: {:reserved, :character}
  
  def tag([[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16]) when is_c(b1) and is_h(b2) and is_a(b3) and is_r(b4) and is_a(b5) and is_c(b6) and is_t(b7) and is_e(b8) and is_r(b9) and b10 in ~c"_" and is_l(b11) and is_e(b12) and is_n(b13) and is_g(b14) and is_t(b15) and is_h(b16), do: {:reserved, :character_length}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_c(b1) and is_h(b2) and is_e(b3) and is_c(b4) and is_k(b5), do: {:reserved, :check}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_c(b1) and is_l(b2) and is_a(b3) and is_s(b4) and is_s(b5) and is_i(b6) and is_f(b7) and is_i(b8) and is_e(b9) and is_r(b10), do: {:reserved, :classifier}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_c(b1) and is_l(b2) and is_o(b3) and is_b(b4), do: {:reserved, :clob}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_c(b1) and is_l(b2) and is_o(b3) and is_s(b4) and is_e(b5), do: {:reserved, :close}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_c(b1) and is_o(b2) and is_a(b3) and is_l(b4) and is_e(b5) and is_s(b6) and is_c(b7) and is_e(b8), do: {:reserved, :coalesce}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_c(b1) and is_o(b2) and is_l(b3) and is_l(b4) and is_a(b5) and is_t(b6) and is_e(b7), do: {:reserved, :collate}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_c(b1) and is_o(b2) and is_l(b3) and is_l(b4) and is_e(b5) and is_c(b6) and is_t(b7), do: {:reserved, :collect}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_c(b1) and is_o(b2) and is_l(b3) and is_u(b4) and is_m(b5) and is_n(b6), do: {:reserved, :column}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_c(b1) and is_o(b2) and is_m(b3) and is_m(b4) and is_i(b5) and is_t(b6), do: {:reserved, :commit}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_c(b1) and is_o(b2) and is_n(b3) and is_d(b4) and is_i(b5) and is_t(b6) and is_i(b7) and is_o(b8) and is_n(b9), do: {:reserved, :condition}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_c(b1) and is_o(b2) and is_n(b3) and is_n(b4) and is_e(b5) and is_c(b6) and is_t(b7), do: {:reserved, :connect}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_c(b1) and is_o(b2) and is_n(b3) and is_s(b4) and is_t(b5) and is_r(b6) and is_a(b7) and is_i(b8) and is_n(b9) and is_t(b10), do: {:reserved, :constraint}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_c(b1) and is_o(b2) and is_n(b3) and is_t(b4) and is_a(b5) and is_i(b6) and is_n(b7) and is_s(b8), do: {:reserved, :contains}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_c(b1) and is_o(b2) and is_n(b3) and is_v(b4) and is_e(b5) and is_r(b6) and is_t(b7), do: {:reserved, :convert}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_c(b1) and is_o(b2) and is_p(b3) and is_y(b4), do: {:reserved, :copy}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_c(b1) and is_o(b2) and is_r(b3) and is_r(b4), do: {:reserved, :corr}
  
  def tag([[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when is_c(b1) and is_o(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_s(b6) and is_p(b7) and is_o(b8) and is_n(b9) and is_d(b10) and is_i(b11) and is_n(b12) and is_g(b13), do: {:reserved, :corresponding}
  
  def tag([[[[], b1], b2], b3]) when is_c(b1) and is_o(b2) and is_s(b3), do: {:reserved, :cos}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_c(b1) and is_o(b2) and is_s(b3) and is_h(b4), do: {:reserved, :cosh}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_c(b1) and is_o(b2) and is_u(b3) and is_n(b4) and is_t(b5), do: {:reserved, :count}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_c(b1) and is_o(b2) and is_v(b3) and is_a(b4) and is_r(b5) and b6 in ~c"_" and is_p(b7) and is_o(b8) and is_p(b9), do: {:reserved, :covar_pop}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_c(b1) and is_o(b2) and is_v(b3) and is_a(b4) and is_r(b5) and b6 in ~c"_" and is_s(b7) and is_a(b8) and is_m(b9) and is_p(b10), do: {:reserved, :covar_samp}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_c(b1) and is_r(b2) and is_e(b3) and is_a(b4) and is_t(b5) and is_e(b6), do: {:reserved, :create}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_c(b1) and is_r(b2) and is_o(b3) and is_s(b4) and is_s(b5), do: {:reserved, :cross}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_c(b1) and is_u(b2) and is_b(b3) and is_e(b4), do: {:reserved, :cube}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_c(b1) and is_u(b2) and is_m(b3) and is_e(b4) and b5 in ~c"_" and is_d(b6) and is_i(b7) and is_s(b8) and is_t(b9), do: {:reserved, :cume_dist}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7), do: {:reserved, :current}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_c(b9) and is_a(b10) and is_t(b11) and is_a(b12) and is_l(b13) and is_o(b14) and is_g(b15), do: {:reserved, :current_catalog}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_d(b9) and is_a(b10) and is_t(b11) and is_e(b12), do: {:reserved, :current_date}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25], b26], b27], b28], b29], b30], b31]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_d(b9) and is_e(b10) and is_f(b11) and is_a(b12) and is_u(b13) and is_l(b14) and is_t(b15) and b16 in ~c"_" and is_t(b17) and is_r(b18) and is_a(b19) and is_n(b20) and is_s(b21) and is_f(b22) and is_o(b23) and is_r(b24) and is_m(b25) and b26 in ~c"_" and is_g(b27) and is_r(b28) and is_o(b29) and is_u(b30) and is_p(b31), do: {:reserved, :current_default_transform_group}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_p(b9) and is_a(b10) and is_t(b11) and is_h(b12), do: {:reserved, :current_path}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_r(b9) and is_o(b10) and is_l(b11) and is_e(b12), do: {:reserved, :current_role}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_r(b9) and is_o(b10) and is_w(b11), do: {:reserved, :current_row}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_s(b9) and is_c(b10) and is_h(b11) and is_e(b12) and is_m(b13) and is_a(b14), do: {:reserved, :current_schema}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_t(b9) and is_i(b10) and is_m(b11) and is_e(b12), do: {:reserved, :current_time}
  
  def tag([[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_t(b9) and is_i(b10) and is_m(b11) and is_e(b12) and is_s(b13) and is_t(b14) and is_a(b15) and is_m(b16) and is_p(b17), do: {:reserved, :current_timestamp}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25], b26], b27], b28], b29], b30], b31], b32]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_t(b9) and is_r(b10) and is_a(b11) and is_n(b12) and is_s(b13) and is_f(b14) and is_o(b15) and is_r(b16) and is_m(b17) and b18 in ~c"_" and is_g(b19) and is_r(b20) and is_o(b21) and is_u(b22) and is_p(b23) and b24 in ~c"_" and is_f(b25) and is_o(b26) and is_r(b27) and b28 in ~c"_" and is_t(b29) and is_y(b30) and is_p(b31) and is_e(b32), do: {:reserved, :current_transform_group_for_type}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_c(b1) and is_u(b2) and is_r(b3) and is_r(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_u(b9) and is_s(b10) and is_e(b11) and is_r(b12), do: {:reserved, :current_user}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_c(b1) and is_u(b2) and is_r(b3) and is_s(b4) and is_o(b5) and is_r(b6), do: {:reserved, :cursor}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_c(b1) and is_y(b2) and is_c(b3) and is_l(b4) and is_e(b5), do: {:reserved, :cycle}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_d(b1) and is_a(b2) and is_t(b3) and is_e(b4), do: {:reserved, :date}
  
  def tag([[[[], b1], b2], b3]) when is_d(b1) and is_a(b2) and is_y(b3), do: {:reserved, :day}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_d(b1) and is_e(b2) and is_a(b3) and is_l(b4) and is_l(b5) and is_o(b6) and is_c(b7) and is_a(b8) and is_t(b9) and is_e(b10), do: {:reserved, :deallocate}
  
  def tag([[[[], b1], b2], b3]) when is_d(b1) and is_e(b2) and is_c(b3), do: {:reserved, :dec}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_d(b1) and is_e(b2) and is_c(b3) and is_f(b4) and is_l(b5) and is_o(b6) and is_a(b7) and is_t(b8), do: {:reserved, :decfloat}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_d(b1) and is_e(b2) and is_c(b3) and is_i(b4) and is_m(b5) and is_a(b6) and is_l(b7), do: {:reserved, :decimal}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_d(b1) and is_e(b2) and is_c(b3) and is_l(b4) and is_a(b5) and is_r(b6) and is_e(b7), do: {:reserved, :declare}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_d(b1) and is_e(b2) and is_f(b3) and is_a(b4) and is_u(b5) and is_l(b6) and is_t(b7), do: {:reserved, :default}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_d(b1) and is_e(b2) and is_f(b3) and is_i(b4) and is_n(b5) and is_e(b6), do: {:reserved, :define}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_d(b1) and is_e(b2) and is_l(b3) and is_e(b4) and is_t(b5) and is_e(b6), do: {:reserved, :delete}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_d(b1) and is_e(b2) and is_n(b3) and is_s(b4) and is_e(b5) and b6 in ~c"_" and is_r(b7) and is_a(b8) and is_n(b9) and is_k(b10), do: {:reserved, :dense_rank}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_d(b1) and is_e(b2) and is_r(b3) and is_e(b4) and is_f(b5), do: {:reserved, :deref}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_d(b1) and is_e(b2) and is_s(b3) and is_c(b4) and is_r(b5) and is_i(b6) and is_b(b7) and is_e(b8), do: {:reserved, :describe}
  
  def tag([[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when is_d(b1) and is_e(b2) and is_t(b3) and is_e(b4) and is_r(b5) and is_m(b6) and is_i(b7) and is_n(b8) and is_i(b9) and is_s(b10) and is_t(b11) and is_i(b12) and is_c(b13), do: {:reserved, :deterministic}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_d(b1) and is_i(b2) and is_s(b3) and is_c(b4) and is_o(b5) and is_n(b6) and is_n(b7) and is_e(b8) and is_c(b9) and is_t(b10), do: {:reserved, :disconnect}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_d(b1) and is_i(b2) and is_s(b3) and is_t(b4) and is_i(b5) and is_n(b6) and is_c(b7) and is_t(b8), do: {:reserved, :distinct}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_d(b1) and is_o(b2) and is_u(b3) and is_b(b4) and is_l(b5) and is_e(b6), do: {:reserved, :double}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_d(b1) and is_r(b2) and is_o(b3) and is_p(b4), do: {:reserved, :drop}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_d(b1) and is_y(b2) and is_n(b3) and is_a(b4) and is_m(b5) and is_i(b6) and is_c(b7), do: {:reserved, :dynamic}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_e(b1) and is_a(b2) and is_c(b3) and is_h(b4), do: {:reserved, :each}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_e(b1) and is_l(b2) and is_e(b3) and is_m(b4) and is_e(b5) and is_n(b6) and is_t(b7), do: {:reserved, :element}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_e(b1) and is_l(b2) and is_s(b3) and is_e(b4), do: {:reserved, :else}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_e(b1) and is_m(b2) and is_p(b3) and is_t(b4) and is_y(b5), do: {:reserved, :empty}
  
  def tag([[[[], b1], b2], b3]) when is_e(b1) and is_n(b2) and is_d(b3), do: {:reserved, :end}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_e(b1) and is_n(b2) and is_d(b3) and b4 in ~c"_" and is_f(b5) and is_r(b6) and is_a(b7) and is_m(b8) and is_e(b9), do: {:reserved, :end_frame}
  
  def tag([[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when is_e(b1) and is_n(b2) and is_d(b3) and b4 in ~c"_" and is_p(b5) and is_a(b6) and is_r(b7) and is_t(b8) and is_i(b9) and is_t(b10) and is_i(b11) and is_o(b12) and is_n(b13), do: {:reserved, :end_partition}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_e(b1) and is_n(b2) and is_d(b3) and b4 in ~c"-" and is_e(b5) and is_x(b6) and is_e(b7) and is_c(b8), do: {:reserved, :"end-exec"}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_e(b1) and is_q(b2) and is_u(b3) and is_a(b4) and is_l(b5) and is_s(b6), do: {:reserved, :equals}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_e(b1) and is_s(b2) and is_c(b3) and is_a(b4) and is_p(b5) and is_e(b6), do: {:reserved, :escape}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_e(b1) and is_v(b2) and is_e(b3) and is_r(b4) and is_y(b5), do: {:reserved, :every}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_e(b1) and is_x(b2) and is_c(b3) and is_e(b4) and is_p(b5) and is_t(b6), do: {:reserved, :except}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_e(b1) and is_x(b2) and is_e(b3) and is_c(b4), do: {:reserved, :exec}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_e(b1) and is_x(b2) and is_e(b3) and is_c(b4) and is_u(b5) and is_t(b6) and is_e(b7), do: {:reserved, :execute}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_e(b1) and is_x(b2) and is_i(b3) and is_s(b4) and is_t(b5) and is_s(b6), do: {:reserved, :exists}
  
  def tag([[[[], b1], b2], b3]) when is_e(b1) and is_x(b2) and is_p(b3), do: {:reserved, :exp}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_e(b1) and is_x(b2) and is_t(b3) and is_e(b4) and is_r(b5) and is_n(b6) and is_a(b7) and is_l(b8), do: {:reserved, :external}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_e(b1) and is_x(b2) and is_t(b3) and is_r(b4) and is_a(b5) and is_c(b6) and is_t(b7), do: {:reserved, :extract}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_f(b1) and is_a(b2) and is_l(b3) and is_s(b4) and is_e(b5), do: {:reserved, false}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_f(b1) and is_e(b2) and is_t(b3) and is_c(b4) and is_h(b5), do: {:reserved, :fetch}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_f(b1) and is_i(b2) and is_l(b3) and is_t(b4) and is_e(b5) and is_r(b6), do: {:reserved, :filter}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_f(b1) and is_i(b2) and is_r(b3) and is_s(b4) and is_t(b5) and b6 in ~c"_" and is_v(b7) and is_a(b8) and is_l(b9) and is_u(b10) and is_e(b11), do: {:reserved, :first_value}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_f(b1) and is_l(b2) and is_o(b3) and is_a(b4) and is_t(b5), do: {:reserved, :float}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_f(b1) and is_l(b2) and is_o(b3) and is_o(b4) and is_r(b5), do: {:reserved, :floor}
  
  def tag([[[[], b1], b2], b3]) when is_f(b1) and is_o(b2) and is_r(b3), do: {:reserved, :for}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_f(b1) and is_o(b2) and is_r(b3) and is_e(b4) and is_i(b5) and is_g(b6) and is_n(b7), do: {:reserved, :foreign}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_f(b1) and is_r(b2) and is_a(b3) and is_m(b4) and is_e(b5) and b6 in ~c"_" and is_r(b7) and is_o(b8) and is_w(b9), do: {:reserved, :frame_row}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_f(b1) and is_r(b2) and is_e(b3) and is_e(b4), do: {:reserved, :free}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_f(b1) and is_r(b2) and is_o(b3) and is_m(b4), do: {:reserved, :from}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_f(b1) and is_u(b2) and is_l(b3) and is_l(b4), do: {:reserved, :full}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_f(b1) and is_u(b2) and is_n(b3) and is_c(b4) and is_t(b5) and is_i(b6) and is_o(b7) and is_n(b8), do: {:reserved, :function}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_f(b1) and is_u(b2) and is_s(b3) and is_i(b4) and is_o(b5) and is_n(b6), do: {:reserved, :fusion}
  
  def tag([[[[], b1], b2], b3]) when is_g(b1) and is_e(b2) and is_t(b3), do: {:reserved, :get}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_g(b1) and is_l(b2) and is_o(b3) and is_b(b4) and is_a(b5) and is_l(b6), do: {:reserved, :global}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_g(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_t(b5), do: {:reserved, :grant}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_g(b1) and is_r(b2) and is_e(b3) and is_a(b4) and is_t(b5) and is_e(b6) and is_s(b7) and is_t(b8), do: {:reserved, :greatest}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_g(b1) and is_r(b2) and is_o(b3) and is_u(b4) and is_p(b5), do: {:reserved, :group}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_g(b1) and is_r(b2) and is_o(b3) and is_u(b4) and is_p(b5) and is_i(b6) and is_n(b7) and is_g(b8), do: {:reserved, :grouping}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_g(b1) and is_r(b2) and is_o(b3) and is_u(b4) and is_p(b5) and is_s(b6), do: {:reserved, :groups}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_h(b1) and is_a(b2) and is_v(b3) and is_i(b4) and is_n(b5) and is_g(b6), do: {:reserved, :having}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_h(b1) and is_o(b2) and is_l(b3) and is_d(b4), do: {:reserved, :hold}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_h(b1) and is_o(b2) and is_u(b3) and is_r(b4), do: {:reserved, :hour}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_i(b1) and is_d(b2) and is_e(b3) and is_n(b4) and is_t(b5) and is_i(b6) and is_t(b7) and is_y(b8), do: {:reserved, :identity}
  
  def tag([[[], b1], b2]) when is_i(b1) and is_n(b2), do: {:reserved, :in}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_i(b1) and is_n(b2) and is_d(b3) and is_i(b4) and is_c(b5) and is_a(b6) and is_t(b7) and is_o(b8) and is_r(b9), do: {:reserved, :indicator}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_i(b1) and is_n(b2) and is_i(b3) and is_t(b4) and is_i(b5) and is_a(b6) and is_l(b7), do: {:reserved, :initial}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_i(b1) and is_n(b2) and is_n(b3) and is_e(b4) and is_r(b5), do: {:reserved, :inner}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_i(b1) and is_n(b2) and is_o(b3) and is_u(b4) and is_t(b5), do: {:reserved, :inout}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_i(b1) and is_n(b2) and is_s(b3) and is_e(b4) and is_n(b5) and is_s(b6) and is_i(b7) and is_t(b8) and is_i(b9) and is_v(b10) and is_e(b11), do: {:reserved, :insensitive}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_i(b1) and is_n(b2) and is_s(b3) and is_e(b4) and is_r(b5) and is_t(b6), do: {:reserved, :insert}
  
  def tag([[[[], b1], b2], b3]) when is_i(b1) and is_n(b2) and is_t(b3), do: {:reserved, :int}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_i(b1) and is_n(b2) and is_t(b3) and is_e(b4) and is_g(b5) and is_e(b6) and is_r(b7), do: {:reserved, :integer}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_i(b1) and is_n(b2) and is_t(b3) and is_e(b4) and is_r(b5) and is_s(b6) and is_e(b7) and is_c(b8) and is_t(b9), do: {:reserved, :intersect}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_i(b1) and is_n(b2) and is_t(b3) and is_e(b4) and is_r(b5) and is_s(b6) and is_e(b7) and is_c(b8) and is_t(b9) and is_i(b10) and is_o(b11) and is_n(b12), do: {:reserved, :intersection}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_i(b1) and is_n(b2) and is_t(b3) and is_e(b4) and is_r(b5) and is_v(b6) and is_a(b7) and is_l(b8), do: {:reserved, :interval}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_i(b1) and is_n(b2) and is_t(b3) and is_o(b4), do: {:reserved, :into}
  
  def tag([[[], b1], b2]) when is_i(b1) and is_s(b2), do: {:reserved, :is}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_j(b1) and is_o(b2) and is_i(b3) and is_n(b4), do: {:reserved, :join}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4), do: {:reserved, :json}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_a(b6) and is_r(b7) and is_r(b8) and is_a(b9) and is_y(b10), do: {:reserved, :json_array}
  
  def tag([[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_a(b6) and is_r(b7) and is_r(b8) and is_a(b9) and is_y(b10) and is_a(b11) and is_g(b12) and is_g(b13), do: {:reserved, :json_arrayagg}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_e(b6) and is_x(b7) and is_i(b8) and is_s(b9) and is_t(b10) and is_s(b11), do: {:reserved, :json_exists}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_o(b6) and is_b(b7) and is_j(b8) and is_e(b9) and is_c(b10) and is_t(b11), do: {:reserved, :json_object}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_o(b6) and is_b(b7) and is_j(b8) and is_e(b9) and is_c(b10) and is_t(b11) and is_a(b12) and is_g(b13) and is_g(b14), do: {:reserved, :json_objectagg}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_q(b6) and is_u(b7) and is_e(b8) and is_r(b9) and is_y(b10), do: {:reserved, :json_query}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_s(b6) and is_c(b7) and is_a(b8) and is_l(b9) and is_a(b10) and is_r(b11), do: {:reserved, :json_scalar}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_s(b6) and is_e(b7) and is_r(b8) and is_i(b9) and is_a(b10) and is_l(b11) and is_i(b12) and is_z(b13) and is_e(b14), do: {:reserved, :json_serialize}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_t(b6) and is_a(b7) and is_b(b8) and is_l(b9) and is_e(b10), do: {:reserved, :json_table}
  
  def tag([[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_t(b6) and is_a(b7) and is_b(b8) and is_l(b9) and is_e(b10) and b11 in ~c"_" and is_p(b12) and is_r(b13) and is_i(b14) and is_m(b15) and is_i(b16) and is_t(b17) and is_i(b18) and is_v(b19) and is_e(b20), do: {:reserved, :json_table_primitive}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_j(b1) and is_s(b2) and is_o(b3) and is_n(b4) and b5 in ~c"_" and is_v(b6) and is_a(b7) and is_l(b8) and is_u(b9) and is_e(b10), do: {:reserved, :json_value}
  
  def tag([[[[], b1], b2], b3]) when is_l(b1) and is_a(b2) and is_g(b3), do: {:reserved, :lag}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_l(b1) and is_a(b2) and is_n(b3) and is_g(b4) and is_u(b5) and is_a(b6) and is_g(b7) and is_e(b8), do: {:reserved, :language}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_l(b1) and is_a(b2) and is_r(b3) and is_g(b4) and is_e(b5), do: {:reserved, :large}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_l(b1) and is_a(b2) and is_s(b3) and is_t(b4) and b5 in ~c"_" and is_v(b6) and is_a(b7) and is_l(b8) and is_u(b9) and is_e(b10), do: {:reserved, :last_value}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_l(b1) and is_a(b2) and is_t(b3) and is_e(b4) and is_r(b5) and is_a(b6) and is_l(b7), do: {:reserved, :lateral}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_l(b1) and is_e(b2) and is_a(b3) and is_d(b4), do: {:reserved, :lead}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_l(b1) and is_e(b2) and is_a(b3) and is_d(b4) and is_i(b5) and is_n(b6) and is_g(b7), do: {:reserved, :leading}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_l(b1) and is_e(b2) and is_a(b3) and is_s(b4) and is_t(b5), do: {:reserved, :least}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_l(b1) and is_e(b2) and is_f(b3) and is_t(b4), do: {:reserved, :left}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_l(b1) and is_i(b2) and is_k(b3) and is_e(b4), do: {:reserved, :like}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_l(b1) and is_i(b2) and is_k(b3) and is_e(b4) and b5 in ~c"_" and is_r(b6) and is_e(b7) and is_g(b8) and is_e(b9) and is_x(b10), do: {:reserved, :like_regex}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_l(b1) and is_i(b2) and is_s(b3) and is_t(b4) and is_a(b5) and is_g(b6) and is_g(b7), do: {:reserved, :listagg}
  
  def tag([[[], b1], b2]) when is_l(b1) and is_n(b2), do: {:reserved, :ln}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_l(b1) and is_o(b2) and is_c(b3) and is_a(b4) and is_l(b5), do: {:reserved, :local}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_l(b1) and is_o(b2) and is_c(b3) and is_a(b4) and is_l(b5) and is_t(b6) and is_i(b7) and is_m(b8) and is_e(b9), do: {:reserved, :localtime}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_l(b1) and is_o(b2) and is_c(b3) and is_a(b4) and is_l(b5) and is_t(b6) and is_i(b7) and is_m(b8) and is_e(b9) and is_s(b10) and is_t(b11) and is_a(b12) and is_m(b13) and is_p(b14), do: {:reserved, :localtimestamp}
  
  def tag([[[[], b1], b2], b3]) when is_l(b1) and is_o(b2) and is_g(b3), do: {:reserved, :log}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_l(b1) and is_o(b2) and is_g(b3) and b4 in ~c"1" and b5 in ~c"0", do: {:reserved, :log10}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_l(b1) and is_o(b2) and is_w(b3) and is_e(b4) and is_r(b5), do: {:reserved, :lower}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_l(b1) and is_p(b2) and is_a(b3) and is_d(b4), do: {:reserved, :lpad}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_l(b1) and is_t(b2) and is_r(b3) and is_i(b4) and is_m(b5), do: {:reserved, :ltrim}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_m(b1) and is_a(b2) and is_t(b3) and is_c(b4) and is_h(b5), do: {:reserved, :match}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_m(b1) and is_a(b2) and is_t(b3) and is_c(b4) and is_h(b5) and b6 in ~c"_" and is_n(b7) and is_u(b8) and is_m(b9) and is_b(b10) and is_e(b11) and is_r(b12), do: {:reserved, :match_number}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_m(b1) and is_a(b2) and is_t(b3) and is_c(b4) and is_h(b5) and b6 in ~c"_" and is_r(b7) and is_e(b8) and is_c(b9) and is_o(b10) and is_g(b11) and is_n(b12) and is_i(b13) and is_z(b14) and is_e(b15), do: {:reserved, :match_recognize}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_m(b1) and is_a(b2) and is_t(b3) and is_c(b4) and is_h(b5) and is_e(b6) and is_s(b7), do: {:reserved, :matches}
  
  def tag([[[[], b1], b2], b3]) when is_m(b1) and is_a(b2) and is_x(b3), do: {:reserved, :max}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_m(b1) and is_e(b2) and is_m(b3) and is_b(b4) and is_e(b5) and is_r(b6), do: {:reserved, :member}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_m(b1) and is_e(b2) and is_r(b3) and is_g(b4) and is_e(b5), do: {:reserved, :merge}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_m(b1) and is_e(b2) and is_t(b3) and is_h(b4) and is_o(b5) and is_d(b6), do: {:reserved, :method}
  
  def tag([[[[], b1], b2], b3]) when is_m(b1) and is_i(b2) and is_n(b3), do: {:reserved, :min}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_m(b1) and is_i(b2) and is_n(b3) and is_u(b4) and is_t(b5) and is_e(b6), do: {:reserved, :minute}
  
  def tag([[[[], b1], b2], b3]) when is_m(b1) and is_o(b2) and is_d(b3), do: {:reserved, :mod}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_m(b1) and is_o(b2) and is_d(b3) and is_i(b4) and is_f(b5) and is_i(b6) and is_e(b7) and is_s(b8), do: {:reserved, :modifies}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_m(b1) and is_o(b2) and is_d(b3) and is_u(b4) and is_l(b5) and is_e(b6), do: {:reserved, :module}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_m(b1) and is_o(b2) and is_n(b3) and is_t(b4) and is_h(b5), do: {:reserved, :month}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_m(b1) and is_u(b2) and is_l(b3) and is_t(b4) and is_i(b5) and is_s(b6) and is_e(b7) and is_t(b8), do: {:reserved, :multiset}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_n(b1) and is_a(b2) and is_t(b3) and is_i(b4) and is_o(b5) and is_n(b6) and is_a(b7) and is_l(b8), do: {:reserved, :national}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_n(b1) and is_a(b2) and is_t(b3) and is_u(b4) and is_r(b5) and is_a(b6) and is_l(b7), do: {:reserved, :natural}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_n(b1) and is_c(b2) and is_h(b3) and is_a(b4) and is_r(b5), do: {:reserved, :nchar}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_n(b1) and is_c(b2) and is_l(b3) and is_o(b4) and is_b(b5), do: {:reserved, :nclob}
  
  def tag([[[[], b1], b2], b3]) when is_n(b1) and is_e(b2) and is_w(b3), do: {:reserved, :new}
  
  def tag([[[], b1], b2]) when is_n(b1) and is_o(b2), do: {:reserved, :no}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_n(b1) and is_o(b2) and is_n(b3) and is_e(b4), do: {:reserved, :none}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_n(b1) and is_o(b2) and is_r(b3) and is_m(b4) and is_a(b5) and is_l(b6) and is_i(b7) and is_z(b8) and is_e(b9), do: {:reserved, :normalize}
  
  def tag([[[[], b1], b2], b3]) when is_n(b1) and is_o(b2) and is_t(b3), do: {:reserved, :not}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_n(b1) and is_t(b2) and is_h(b3) and b4 in ~c"_" and is_v(b5) and is_a(b6) and is_l(b7) and is_u(b8) and is_e(b9), do: {:reserved, :nth_value}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_n(b1) and is_t(b2) and is_i(b3) and is_l(b4) and is_e(b5), do: {:reserved, :ntile}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_n(b1) and is_u(b2) and is_l(b3) and is_l(b4), do: {:reserved, :null}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_n(b1) and is_u(b2) and is_l(b3) and is_l(b4) and is_i(b5) and is_f(b6), do: {:reserved, :nullif}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_n(b1) and is_u(b2) and is_m(b3) and is_e(b4) and is_r(b5) and is_i(b6) and is_c(b7), do: {:reserved, :numeric}
  
  def tag([[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17]) when is_o(b1) and is_c(b2) and is_c(b3) and is_u(b4) and is_r(b5) and is_r(b6) and is_e(b7) and is_n(b8) and is_c(b9) and is_e(b10) and is_s(b11) and b12 in ~c"_" and is_r(b13) and is_e(b14) and is_g(b15) and is_e(b16) and is_x(b17), do: {:reserved, :occurrences_regex}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_o(b1) and is_c(b2) and is_t(b3) and is_e(b4) and is_t(b5) and b6 in ~c"_" and is_l(b7) and is_e(b8) and is_n(b9) and is_g(b10) and is_t(b11) and is_h(b12), do: {:reserved, :octet_length}
  
  def tag([[[], b1], b2]) when is_o(b1) and is_f(b2), do: {:reserved, :of}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_o(b1) and is_f(b2) and is_f(b3) and is_s(b4) and is_e(b5) and is_t(b6), do: {:reserved, :offset}
  
  def tag([[[[], b1], b2], b3]) when is_o(b1) and is_l(b2) and is_d(b3), do: {:reserved, :old}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_o(b1) and is_m(b2) and is_i(b3) and is_t(b4), do: {:reserved, :omit}
  
  def tag([[[], b1], b2]) when is_o(b1) and is_n(b2), do: {:reserved, :on}
  
  def tag([[[[], b1], b2], b3]) when is_o(b1) and is_n(b2) and is_e(b3), do: {:reserved, :one}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_o(b1) and is_n(b2) and is_l(b3) and is_y(b4), do: {:reserved, :only}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_o(b1) and is_p(b2) and is_e(b3) and is_n(b4), do: {:reserved, :open}
  
  def tag([[[], b1], b2]) when is_o(b1) and is_r(b2), do: {:reserved, :or}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_o(b1) and is_r(b2) and is_d(b3) and is_e(b4) and is_r(b5), do: {:reserved, :order}
  
  def tag([[[[], b1], b2], b3]) when is_o(b1) and is_u(b2) and is_t(b3), do: {:reserved, :out}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_o(b1) and is_u(b2) and is_t(b3) and is_e(b4) and is_r(b5), do: {:reserved, :outer}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_o(b1) and is_v(b2) and is_e(b3) and is_r(b4), do: {:reserved, :over}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_o(b1) and is_v(b2) and is_e(b3) and is_r(b4) and is_l(b5) and is_a(b6) and is_p(b7) and is_s(b8), do: {:reserved, :overlaps}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_o(b1) and is_v(b2) and is_e(b3) and is_r(b4) and is_l(b5) and is_a(b6) and is_y(b7), do: {:reserved, :overlay}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_p(b1) and is_a(b2) and is_r(b3) and is_a(b4) and is_m(b5) and is_e(b6) and is_t(b7) and is_e(b8) and is_r(b9), do: {:reserved, :parameter}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_p(b1) and is_a(b2) and is_r(b3) and is_t(b4) and is_i(b5) and is_t(b6) and is_i(b7) and is_o(b8) and is_n(b9), do: {:reserved, :partition}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_p(b1) and is_a(b2) and is_t(b3) and is_t(b4) and is_e(b5) and is_r(b6) and is_n(b7), do: {:reserved, :pattern}
  
  def tag([[[[], b1], b2], b3]) when is_p(b1) and is_e(b2) and is_r(b3), do: {:reserved, :per}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_p(b1) and is_e(b2) and is_r(b3) and is_c(b4) and is_e(b5) and is_n(b6) and is_t(b7), do: {:reserved, :percent}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_p(b1) and is_e(b2) and is_r(b3) and is_c(b4) and is_e(b5) and is_n(b6) and is_t(b7) and b8 in ~c"_" and is_r(b9) and is_a(b10) and is_n(b11) and is_k(b12), do: {:reserved, :percent_rank}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_p(b1) and is_e(b2) and is_r(b3) and is_c(b4) and is_e(b5) and is_n(b6) and is_t(b7) and is_i(b8) and is_l(b9) and is_e(b10) and b11 in ~c"_" and is_c(b12) and is_o(b13) and is_n(b14) and is_t(b15), do: {:reserved, :percentile_cont}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_p(b1) and is_e(b2) and is_r(b3) and is_c(b4) and is_e(b5) and is_n(b6) and is_t(b7) and is_i(b8) and is_l(b9) and is_e(b10) and b11 in ~c"_" and is_d(b12) and is_i(b13) and is_s(b14) and is_c(b15), do: {:reserved, :percentile_disc}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_p(b1) and is_e(b2) and is_r(b3) and is_i(b4) and is_o(b5) and is_d(b6), do: {:reserved, :period}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_p(b1) and is_o(b2) and is_r(b3) and is_t(b4) and is_i(b5) and is_o(b6) and is_n(b7), do: {:reserved, :portion}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_p(b1) and is_o(b2) and is_s(b3) and is_i(b4) and is_t(b5) and is_i(b6) and is_o(b7) and is_n(b8), do: {:reserved, :position}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_p(b1) and is_o(b2) and is_s(b3) and is_i(b4) and is_t(b5) and is_i(b6) and is_o(b7) and is_n(b8) and b9 in ~c"_" and is_r(b10) and is_e(b11) and is_g(b12) and is_e(b13) and is_x(b14), do: {:reserved, :position_regex}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_p(b1) and is_o(b2) and is_w(b3) and is_e(b4) and is_r(b5), do: {:reserved, :power}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_p(b1) and is_r(b2) and is_e(b3) and is_c(b4) and is_e(b5) and is_d(b6) and is_e(b7) and is_s(b8), do: {:reserved, :precedes}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_p(b1) and is_r(b2) and is_e(b3) and is_c(b4) and is_i(b5) and is_s(b6) and is_i(b7) and is_o(b8) and is_n(b9), do: {:reserved, :precision}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_p(b1) and is_r(b2) and is_e(b3) and is_p(b4) and is_a(b5) and is_r(b6) and is_e(b7), do: {:reserved, :prepare}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_p(b1) and is_r(b2) and is_i(b3) and is_m(b4) and is_a(b5) and is_r(b6) and is_y(b7), do: {:reserved, :primary}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_p(b1) and is_r(b2) and is_o(b3) and is_c(b4) and is_e(b5) and is_d(b6) and is_u(b7) and is_r(b8) and is_e(b9), do: {:reserved, :procedure}
  
  def tag([[[[], b1], b2], b3]) when is_p(b1) and is_t(b2) and is_f(b3), do: {:reserved, :ptf}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_r(b1) and is_a(b2) and is_n(b3) and is_g(b4) and is_e(b5), do: {:reserved, :range}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_r(b1) and is_a(b2) and is_n(b3) and is_k(b4), do: {:reserved, :rank}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_r(b1) and is_e(b2) and is_a(b3) and is_d(b4) and is_s(b5), do: {:reserved, :reads}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_r(b1) and is_e(b2) and is_a(b3) and is_l(b4), do: {:reserved, :real}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_r(b1) and is_e(b2) and is_c(b3) and is_u(b4) and is_r(b5) and is_s(b6) and is_i(b7) and is_v(b8) and is_e(b9), do: {:reserved, :recursive}
  
  def tag([[[[], b1], b2], b3]) when is_r(b1) and is_e(b2) and is_f(b3), do: {:reserved, :ref}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_r(b1) and is_e(b2) and is_f(b3) and is_e(b4) and is_r(b5) and is_e(b6) and is_n(b7) and is_c(b8) and is_e(b9) and is_s(b10), do: {:reserved, :references}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_r(b1) and is_e(b2) and is_f(b3) and is_e(b4) and is_r(b5) and is_e(b6) and is_n(b7) and is_c(b8) and is_i(b9) and is_n(b10) and is_g(b11), do: {:reserved, :referencing}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_r(b1) and is_e(b2) and is_g(b3) and is_r(b4) and b5 in ~c"_" and is_a(b6) and is_v(b7) and is_g(b8) and is_x(b9), do: {:reserved, :regr_avgx}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_r(b1) and is_e(b2) and is_g(b3) and is_r(b4) and b5 in ~c"_" and is_a(b6) and is_v(b7) and is_g(b8) and is_y(b9), do: {:reserved, :regr_avgy}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_r(b1) and is_e(b2) and is_g(b3) and is_r(b4) and b5 in ~c"_" and is_c(b6) and is_o(b7) and is_u(b8) and is_n(b9) and is_t(b10), do: {:reserved, :regr_count}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_r(b1) and is_e(b2) and is_g(b3) and is_r(b4) and b5 in ~c"_" and is_i(b6) and is_n(b7) and is_t(b8) and is_e(b9) and is_r(b10) and is_c(b11) and is_e(b12) and is_p(b13) and is_t(b14), do: {:reserved, :regr_intercept}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_r(b1) and is_e(b2) and is_g(b3) and is_r(b4) and b5 in ~c"_" and is_r(b6) and b7 in ~c"2", do: {:reserved, :regr_r2}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_r(b1) and is_e(b2) and is_g(b3) and is_r(b4) and b5 in ~c"_" and is_s(b6) and is_l(b7) and is_o(b8) and is_p(b9) and is_e(b10), do: {:reserved, :regr_slope}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_r(b1) and is_e(b2) and is_g(b3) and is_r(b4) and b5 in ~c"_" and is_s(b6) and is_x(b7) and is_x(b8), do: {:reserved, :regr_sxx}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_r(b1) and is_e(b2) and is_g(b3) and is_r(b4) and b5 in ~c"_" and is_s(b6) and is_x(b7) and is_y(b8), do: {:reserved, :regr_sxy}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_r(b1) and is_e(b2) and is_g(b3) and is_r(b4) and b5 in ~c"_" and is_s(b6) and is_y(b7) and is_y(b8), do: {:reserved, :regr_syy}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_r(b1) and is_e(b2) and is_l(b3) and is_e(b4) and is_a(b5) and is_s(b6) and is_e(b7), do: {:reserved, :release}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_r(b1) and is_e(b2) and is_s(b3) and is_u(b4) and is_l(b5) and is_t(b6), do: {:reserved, :result}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_r(b1) and is_e(b2) and is_t(b3) and is_u(b4) and is_r(b5) and is_n(b6), do: {:reserved, :return}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_r(b1) and is_e(b2) and is_t(b3) and is_u(b4) and is_r(b5) and is_n(b6) and is_s(b7), do: {:reserved, :returns}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_r(b1) and is_e(b2) and is_v(b3) and is_o(b4) and is_k(b5) and is_e(b6), do: {:reserved, :revoke}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_r(b1) and is_i(b2) and is_g(b3) and is_h(b4) and is_t(b5), do: {:reserved, :right}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_r(b1) and is_o(b2) and is_l(b3) and is_l(b4) and is_b(b5) and is_a(b6) and is_c(b7) and is_k(b8), do: {:reserved, :rollback}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_r(b1) and is_o(b2) and is_l(b3) and is_l(b4) and is_u(b5) and is_p(b6), do: {:reserved, :rollup}
  
  def tag([[[[], b1], b2], b3]) when is_r(b1) and is_o(b2) and is_w(b3), do: {:reserved, :row}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_r(b1) and is_o(b2) and is_w(b3) and b4 in ~c"_" and is_n(b5) and is_u(b6) and is_m(b7) and is_b(b8) and is_e(b9) and is_r(b10), do: {:reserved, :row_number}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_r(b1) and is_o(b2) and is_w(b3) and is_s(b4), do: {:reserved, :rows}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_r(b1) and is_p(b2) and is_a(b3) and is_d(b4), do: {:reserved, :rpad}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_r(b1) and is_t(b2) and is_r(b3) and is_i(b4) and is_m(b5), do: {:reserved, :rtrim}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_r(b1) and is_u(b2) and is_n(b3) and is_n(b4) and is_i(b5) and is_n(b6) and is_g(b7), do: {:reserved, :running}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_s(b1) and is_a(b2) and is_v(b3) and is_e(b4) and is_p(b5) and is_o(b6) and is_i(b7) and is_n(b8) and is_t(b9), do: {:reserved, :savepoint}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_s(b1) and is_c(b2) and is_o(b3) and is_p(b4) and is_e(b5), do: {:reserved, :scope}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_c(b2) and is_r(b3) and is_o(b4) and is_l(b5) and is_l(b6), do: {:reserved, :scroll}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_e(b2) and is_a(b3) and is_r(b4) and is_c(b5) and is_h(b6), do: {:reserved, :search}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_e(b2) and is_c(b3) and is_o(b4) and is_n(b5) and is_d(b6), do: {:reserved, :second}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_s(b1) and is_e(b2) and is_e(b3) and is_k(b4), do: {:reserved, :seek}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_e(b2) and is_l(b3) and is_e(b4) and is_c(b5) and is_t(b6), do: {:reserved, :select}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_s(b1) and is_e(b2) and is_n(b3) and is_s(b4) and is_i(b5) and is_t(b6) and is_i(b7) and is_v(b8) and is_e(b9), do: {:reserved, :sensitive}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_s(b1) and is_e(b2) and is_s(b3) and is_s(b4) and is_i(b5) and is_o(b6) and is_n(b7) and b8 in ~c"_" and is_u(b9) and is_s(b10) and is_e(b11) and is_r(b12), do: {:reserved, :session_user}
  
  def tag([[[[], b1], b2], b3]) when is_s(b1) and is_e(b2) and is_t(b3), do: {:reserved, :set}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_s(b1) and is_h(b2) and is_o(b3) and is_w(b4), do: {:reserved, :show}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_s(b1) and is_i(b2) and is_m(b3) and is_i(b4) and is_l(b5) and is_a(b6) and is_r(b7), do: {:reserved, :similar}
  
  def tag([[[[], b1], b2], b3]) when is_s(b1) and is_i(b2) and is_n(b3), do: {:reserved, :sin}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_s(b1) and is_i(b2) and is_n(b3) and is_h(b4), do: {:reserved, :sinh}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_s(b1) and is_k(b2) and is_i(b3) and is_p(b4), do: {:reserved, :skip}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_s(b1) and is_m(b2) and is_a(b3) and is_l(b4) and is_l(b5) and is_i(b6) and is_n(b7) and is_t(b8), do: {:reserved, :smallint}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_s(b1) and is_o(b2) and is_m(b3) and is_e(b4), do: {:reserved, :some}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_s(b1) and is_p(b2) and is_e(b3) and is_c(b4) and is_i(b5) and is_f(b6) and is_i(b7) and is_c(b8), do: {:reserved, :specific}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_s(b1) and is_p(b2) and is_e(b3) and is_c(b4) and is_i(b5) and is_f(b6) and is_i(b7) and is_c(b8) and is_t(b9) and is_y(b10) and is_p(b11) and is_e(b12), do: {:reserved, :specifictype}
  
  def tag([[[[], b1], b2], b3]) when is_s(b1) and is_q(b2) and is_l(b3), do: {:reserved, :sql}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_s(b1) and is_q(b2) and is_l(b3) and is_e(b4) and is_x(b5) and is_c(b6) and is_e(b7) and is_p(b8) and is_t(b9) and is_i(b10) and is_o(b11) and is_n(b12), do: {:reserved, :sqlexception}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_s(b1) and is_q(b2) and is_l(b3) and is_s(b4) and is_t(b5) and is_a(b6) and is_t(b7) and is_e(b8), do: {:reserved, :sqlstate}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_s(b1) and is_q(b2) and is_l(b3) and is_w(b4) and is_a(b5) and is_r(b6) and is_n(b7) and is_i(b8) and is_n(b9) and is_g(b10), do: {:reserved, :sqlwarning}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_s(b1) and is_q(b2) and is_r(b3) and is_t(b4), do: {:reserved, :sqrt}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_s(b1) and is_t(b2) and is_a(b3) and is_r(b4) and is_t(b5), do: {:reserved, :start}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_t(b2) and is_a(b3) and is_t(b4) and is_i(b5) and is_c(b6), do: {:reserved, :static}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_s(b1) and is_t(b2) and is_d(b3) and is_d(b4) and is_e(b5) and is_v(b6) and b7 in ~c"_" and is_p(b8) and is_o(b9) and is_p(b10), do: {:reserved, :stddev_pop}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_s(b1) and is_t(b2) and is_d(b3) and is_d(b4) and is_e(b5) and is_v(b6) and b7 in ~c"_" and is_s(b8) and is_a(b9) and is_m(b10) and is_p(b11), do: {:reserved, :stddev_samp}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_s(b1) and is_u(b2) and is_b(b3) and is_m(b4) and is_u(b5) and is_l(b6) and is_t(b7) and is_i(b8) and is_s(b9) and is_e(b10) and is_t(b11), do: {:reserved, :submultiset}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_u(b2) and is_b(b3) and is_s(b4) and is_e(b5) and is_t(b6), do: {:reserved, :subset}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_s(b1) and is_u(b2) and is_b(b3) and is_s(b4) and is_t(b5) and is_r(b6) and is_i(b7) and is_n(b8) and is_g(b9), do: {:reserved, :substring}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_s(b1) and is_u(b2) and is_b(b3) and is_s(b4) and is_t(b5) and is_r(b6) and is_i(b7) and is_n(b8) and is_g(b9) and b10 in ~c"_" and is_r(b11) and is_e(b12) and is_g(b13) and is_e(b14) and is_x(b15), do: {:reserved, :substring_regex}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_s(b1) and is_u(b2) and is_c(b3) and is_c(b4) and is_e(b5) and is_e(b6) and is_d(b7) and is_s(b8), do: {:reserved, :succeeds}
  
  def tag([[[[], b1], b2], b3]) when is_s(b1) and is_u(b2) and is_m(b3), do: {:reserved, :sum}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_s(b1) and is_y(b2) and is_m(b3) and is_m(b4) and is_e(b5) and is_t(b6) and is_r(b7) and is_i(b8) and is_c(b9), do: {:reserved, :symmetric}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_y(b2) and is_s(b3) and is_t(b4) and is_e(b5) and is_m(b6), do: {:reserved, :system}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_s(b1) and is_y(b2) and is_s(b3) and is_t(b4) and is_e(b5) and is_m(b6) and b7 in ~c"_" and is_t(b8) and is_i(b9) and is_m(b10) and is_e(b11), do: {:reserved, :system_time}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_s(b1) and is_y(b2) and is_s(b3) and is_t(b4) and is_e(b5) and is_m(b6) and b7 in ~c"_" and is_u(b8) and is_s(b9) and is_e(b10) and is_r(b11), do: {:reserved, :system_user}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_t(b1) and is_a(b2) and is_b(b3) and is_l(b4) and is_e(b5), do: {:reserved, :table}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_t(b1) and is_a(b2) and is_b(b3) and is_l(b4) and is_e(b5) and is_s(b6) and is_a(b7) and is_m(b8) and is_p(b9) and is_l(b10) and is_e(b11), do: {:reserved, :tablesample}
  
  def tag([[[[], b1], b2], b3]) when is_t(b1) and is_a(b2) and is_n(b3), do: {:reserved, :tan}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_t(b1) and is_a(b2) and is_n(b3) and is_h(b4), do: {:reserved, :tanh}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_t(b1) and is_h(b2) and is_e(b3) and is_n(b4), do: {:reserved, :then}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_t(b1) and is_i(b2) and is_m(b3) and is_e(b4), do: {:reserved, :time}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_t(b1) and is_i(b2) and is_m(b3) and is_e(b4) and is_s(b5) and is_t(b6) and is_a(b7) and is_m(b8) and is_p(b9), do: {:reserved, :timestamp}
  
  def tag([[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when is_t(b1) and is_i(b2) and is_m(b3) and is_e(b4) and is_z(b5) and is_o(b6) and is_n(b7) and is_e(b8) and b9 in ~c"_" and is_h(b10) and is_o(b11) and is_u(b12) and is_r(b13), do: {:reserved, :timezone_hour}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_t(b1) and is_i(b2) and is_m(b3) and is_e(b4) and is_z(b5) and is_o(b6) and is_n(b7) and is_e(b8) and b9 in ~c"_" and is_m(b10) and is_i(b11) and is_n(b12) and is_u(b13) and is_t(b14) and is_e(b15), do: {:reserved, :timezone_minute}
  
  def tag([[[], b1], b2]) when is_t(b1) and is_o(b2), do: {:reserved, :to}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_t(b1) and is_r(b2) and is_a(b3) and is_i(b4) and is_l(b5) and is_i(b6) and is_n(b7) and is_g(b8), do: {:reserved, :trailing}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_t(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_s(b5) and is_l(b6) and is_a(b7) and is_t(b8) and is_e(b9), do: {:reserved, :translate}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_t(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_s(b5) and is_l(b6) and is_a(b7) and is_t(b8) and is_e(b9) and b10 in ~c"_" and is_r(b11) and is_e(b12) and is_g(b13) and is_e(b14) and is_x(b15), do: {:reserved, :translate_regex}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_t(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_s(b5) and is_l(b6) and is_a(b7) and is_t(b8) and is_i(b9) and is_o(b10) and is_n(b11), do: {:reserved, :translation}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_t(b1) and is_r(b2) and is_e(b3) and is_a(b4) and is_t(b5), do: {:reserved, :treat}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_t(b1) and is_r(b2) and is_i(b3) and is_g(b4) and is_g(b5) and is_e(b6) and is_r(b7), do: {:reserved, :trigger}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_t(b1) and is_r(b2) and is_i(b3) and is_m(b4), do: {:reserved, :trim}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_t(b1) and is_r(b2) and is_i(b3) and is_m(b4) and b5 in ~c"_" and is_a(b6) and is_r(b7) and is_r(b8) and is_a(b9) and is_y(b10), do: {:reserved, :trim_array}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_t(b1) and is_r(b2) and is_u(b3) and is_e(b4), do: {:reserved, true}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_t(b1) and is_r(b2) and is_u(b3) and is_n(b4) and is_c(b5) and is_a(b6) and is_t(b7) and is_e(b8), do: {:reserved, :truncate}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_u(b1) and is_e(b2) and is_s(b3) and is_c(b4) and is_a(b5) and is_p(b6) and is_e(b7), do: {:reserved, :uescape}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_u(b1) and is_n(b2) and is_i(b3) and is_o(b4) and is_n(b5), do: {:reserved, :union}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_u(b1) and is_n(b2) and is_i(b3) and is_q(b4) and is_u(b5) and is_e(b6), do: {:reserved, :unique}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_u(b1) and is_n(b2) and is_k(b3) and is_n(b4) and is_o(b5) and is_w(b6) and is_n(b7), do: {:reserved, :unknown}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_u(b1) and is_n(b2) and is_n(b3) and is_e(b4) and is_s(b5) and is_t(b6), do: {:reserved, :unnest}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_u(b1) and is_p(b2) and is_d(b3) and is_a(b4) and is_t(b5) and is_e(b6), do: {:reserved, :update}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_u(b1) and is_p(b2) and is_p(b3) and is_e(b4) and is_r(b5), do: {:reserved, :upper}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_u(b1) and is_s(b2) and is_e(b3) and is_r(b4), do: {:reserved, :user}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_u(b1) and is_s(b2) and is_i(b3) and is_n(b4) and is_g(b5), do: {:reserved, :using}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_v(b1) and is_a(b2) and is_l(b3) and is_u(b4) and is_e(b5), do: {:reserved, :value}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_v(b1) and is_a(b2) and is_l(b3) and is_u(b4) and is_e(b5) and is_s(b6), do: {:reserved, :values}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_v(b1) and is_a(b2) and is_l(b3) and is_u(b4) and is_e(b5) and b6 in ~c"_" and is_o(b7) and is_f(b8), do: {:reserved, :value_of}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_v(b1) and is_a(b2) and is_r(b3) and b4 in ~c"_" and is_p(b5) and is_o(b6) and is_p(b7), do: {:reserved, :var_pop}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_v(b1) and is_a(b2) and is_r(b3) and b4 in ~c"_" and is_s(b5) and is_a(b6) and is_m(b7) and is_p(b8), do: {:reserved, :var_samp}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_v(b1) and is_a(b2) and is_r(b3) and is_b(b4) and is_i(b5) and is_n(b6) and is_a(b7) and is_r(b8) and is_y(b9), do: {:reserved, :varbinary}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_v(b1) and is_a(b2) and is_r(b3) and is_c(b4) and is_h(b5) and is_a(b6) and is_r(b7), do: {:reserved, :varchar}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_v(b1) and is_a(b2) and is_r(b3) and is_y(b4) and is_i(b5) and is_n(b6) and is_g(b7), do: {:reserved, :varying}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_v(b1) and is_e(b2) and is_r(b3) and is_s(b4) and is_i(b5) and is_o(b6) and is_n(b7) and is_i(b8) and is_n(b9) and is_g(b10), do: {:reserved, :versioning}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_w(b1) and is_h(b2) and is_e(b3) and is_n(b4), do: {:reserved, :when}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_w(b1) and is_h(b2) and is_e(b3) and is_n(b4) and is_e(b5) and is_v(b6) and is_e(b7) and is_r(b8), do: {:reserved, :whenever}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_w(b1) and is_h(b2) and is_e(b3) and is_r(b4) and is_e(b5), do: {:reserved, :where}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_w(b1) and is_i(b2) and is_d(b3) and is_t(b4) and is_h(b5) and b6 in ~c"_" and is_b(b7) and is_u(b8) and is_c(b9) and is_k(b10) and is_e(b11) and is_t(b12), do: {:reserved, :width_bucket}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_w(b1) and is_i(b2) and is_n(b3) and is_d(b4) and is_o(b5) and is_w(b6), do: {:reserved, :window}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_w(b1) and is_i(b2) and is_t(b3) and is_h(b4), do: {:reserved, :with}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_w(b1) and is_i(b2) and is_t(b3) and is_h(b4) and is_i(b5) and is_n(b6), do: {:reserved, :within}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_w(b1) and is_i(b2) and is_t(b3) and is_h(b4) and is_o(b5) and is_u(b6) and is_t(b7), do: {:reserved, :without}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_y(b1) and is_e(b2) and is_a(b3) and is_r(b4), do: {:reserved, :year}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_l(b1) and is_i(b2) and is_m(b3) and is_i(b4) and is_t(b5), do: {:reserved, :limit}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_i(b1) and is_l(b2) and is_i(b3) and is_k(b4) and is_e(b5), do: {:reserved, :ilike}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_b(b1) and is_a(b2) and is_c(b3) and is_k(b4) and is_w(b5) and is_a(b6) and is_r(b7) and is_d(b8), do: {:reserved, :backward}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_f(b1) and is_o(b2) and is_r(b3) and is_w(b4) and is_a(b5) and is_r(b6) and is_d(b7), do: {:reserved, :forward}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_i(b1) and is_s(b2) and is_n(b3) and is_u(b4) and is_l(b5) and is_l(b6), do: {:reserved, :isnull}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_n(b1) and is_o(b2) and is_t(b3) and is_n(b4) and is_u(b5) and is_l(b6) and is_l(b7), do: {:reserved, :notnull}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_d(b1) and is_a(b2) and is_t(b3) and is_e(b4) and is_t(b5) and is_i(b6) and is_m(b7) and is_e(b8), do: {:reserved, :datetime}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_f(b1) and is_l(b2) and is_a(b3) and is_g(b4), do: {:reserved, :flag}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_k(b1) and is_e(b2) and is_y(b3) and is_v(b4) and is_a(b5) and is_l(b6) and is_u(b7) and is_e(b8), do: {:reserved, :keyvalue}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_l(b1) and is_a(b2) and is_s(b3) and is_t(b4), do: {:reserved, :last}
  
  def tag([[[[], b1], b2], b3]) when is_l(b1) and is_a(b2) and is_x(b3), do: {:reserved, :lax}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_n(b1) and is_u(b2) and is_m(b3) and is_b(b4) and is_e(b5) and is_r(b6), do: {:reserved, :number}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_s(b1) and is_i(b2) and is_z(b3) and is_e(b4), do: {:reserved, :size}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_t(b2) and is_a(b3) and is_r(b4) and is_t(b5) and is_s(b6), do: {:reserved, :starts}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_t(b2) and is_r(b3) and is_i(b4) and is_c(b5) and is_t(b6), do: {:reserved, :strict}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_t(b2) and is_r(b3) and is_i(b4) and is_n(b5) and is_g(b6), do: {:reserved, :string}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_t(b1) and is_i(b2) and is_m(b3) and is_e(b4) and b5 in ~c"_" and is_t(b6) and is_z(b7), do: {:reserved, :time_tz}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_t(b1) and is_i(b2) and is_m(b3) and is_e(b4) and is_s(b5) and is_t(b6) and is_a(b7) and is_m(b8) and is_p(b9) and b10 in ~c"_" and is_t(b11) and is_z(b12), do: {:reserved, :timestamp_tz}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_t(b1) and is_y(b2) and is_p(b3) and is_e(b4), do: {:reserved, :type}
  
  
  def tag([[], b1]) when is_a(b1), do: {:non_reserved, :a}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_a(b1) and is_b(b2) and is_s(b3) and is_o(b4) and is_l(b5) and is_u(b6) and is_t(b7) and is_e(b8), do: {:non_reserved, :absolute}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_a(b1) and is_c(b2) and is_t(b3) and is_i(b4) and is_o(b5) and is_n(b6), do: {:non_reserved, :action}
  
  def tag([[[[], b1], b2], b3]) when is_a(b1) and is_d(b2) and is_a(b3), do: {:non_reserved, :ada}
  
  def tag([[[[], b1], b2], b3]) when is_a(b1) and is_d(b2) and is_d(b3), do: {:non_reserved, :add}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_a(b1) and is_d(b2) and is_m(b3) and is_i(b4) and is_n(b5), do: {:non_reserved, :admin}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_a(b1) and is_f(b2) and is_t(b3) and is_e(b4) and is_r(b5), do: {:non_reserved, :after}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_a(b1) and is_l(b2) and is_w(b3) and is_a(b4) and is_y(b5) and is_s(b6), do: {:non_reserved, :always}
  
  def tag([[[[], b1], b2], b3]) when is_a(b1) and is_s(b2) and is_c(b3), do: {:non_reserved, :asc}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_a(b1) and is_s(b2) and is_s(b3) and is_e(b4) and is_r(b5) and is_t(b6) and is_i(b7) and is_o(b8) and is_n(b9), do: {:non_reserved, :assertion}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_a(b1) and is_s(b2) and is_s(b3) and is_i(b4) and is_g(b5) and is_n(b6) and is_m(b7) and is_e(b8) and is_n(b9) and is_t(b10), do: {:non_reserved, :assignment}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_a(b1) and is_t(b2) and is_t(b3) and is_r(b4) and is_i(b5) and is_b(b6) and is_u(b7) and is_t(b8) and is_e(b9), do: {:non_reserved, :attribute}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_a(b1) and is_t(b2) and is_t(b3) and is_r(b4) and is_i(b5) and is_b(b6) and is_u(b7) and is_t(b8) and is_e(b9) and is_s(b10), do: {:non_reserved, :attributes}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_b(b1) and is_e(b2) and is_f(b3) and is_o(b4) and is_r(b5) and is_e(b6), do: {:non_reserved, :before}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_b(b1) and is_e(b2) and is_r(b3) and is_n(b4) and is_o(b5) and is_u(b6) and is_l(b7) and is_l(b8) and is_i(b9), do: {:non_reserved, :bernoulli}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_b(b1) and is_r(b2) and is_e(b3) and is_a(b4) and is_d(b5) and is_t(b6) and is_h(b7), do: {:non_reserved, :breadth}
  
  def tag([[], b1]) when is_c(b1), do: {:non_reserved, :c}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_c(b1) and is_a(b2) and is_s(b3) and is_c(b4) and is_a(b5) and is_d(b6) and is_e(b7), do: {:non_reserved, :cascade}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_c(b1) and is_a(b2) and is_t(b3) and is_a(b4) and is_l(b5) and is_o(b6) and is_g(b7), do: {:non_reserved, :catalog}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_c(b1) and is_a(b2) and is_t(b3) and is_a(b4) and is_l(b5) and is_o(b6) and is_g(b7) and b8 in ~c"_" and is_n(b9) and is_a(b10) and is_m(b11) and is_e(b12), do: {:non_reserved, :catalog_name}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_c(b1) and is_h(b2) and is_a(b3) and is_i(b4) and is_n(b5), do: {:non_reserved, :chain}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_c(b1) and is_h(b2) and is_a(b3) and is_i(b4) and is_n(b5) and is_i(b6) and is_n(b7) and is_g(b8), do: {:non_reserved, :chaining}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21]) when is_c(b1) and is_h(b2) and is_a(b3) and is_r(b4) and is_a(b5) and is_c(b6) and is_t(b7) and is_e(b8) and is_r(b9) and b10 in ~c"_" and is_s(b11) and is_e(b12) and is_t(b13) and b14 in ~c"_" and is_c(b15) and is_a(b16) and is_t(b17) and is_a(b18) and is_l(b19) and is_o(b20) and is_g(b21), do: {:non_reserved, :character_set_catalog}
  
  def tag([[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18]) when is_c(b1) and is_h(b2) and is_a(b3) and is_r(b4) and is_a(b5) and is_c(b6) and is_t(b7) and is_e(b8) and is_r(b9) and b10 in ~c"_" and is_s(b11) and is_e(b12) and is_t(b13) and b14 in ~c"_" and is_n(b15) and is_a(b16) and is_m(b17) and is_e(b18), do: {:non_reserved, :character_set_name}
  
  def tag([[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20]) when is_c(b1) and is_h(b2) and is_a(b3) and is_r(b4) and is_a(b5) and is_c(b6) and is_t(b7) and is_e(b8) and is_r(b9) and b10 in ~c"_" and is_s(b11) and is_e(b12) and is_t(b13) and b14 in ~c"_" and is_s(b15) and is_c(b16) and is_h(b17) and is_e(b18) and is_m(b19) and is_a(b20), do: {:non_reserved, :character_set_schema}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_c(b1) and is_h(b2) and is_a(b3) and is_r(b4) and is_a(b5) and is_c(b6) and is_t(b7) and is_e(b8) and is_r(b9) and is_i(b10) and is_s(b11) and is_t(b12) and is_i(b13) and is_c(b14) and is_s(b15), do: {:non_reserved, :characteristics}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_c(b1) and is_h(b2) and is_a(b3) and is_r(b4) and is_a(b5) and is_c(b6) and is_t(b7) and is_e(b8) and is_r(b9) and is_s(b10), do: {:non_reserved, :characters}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_c(b1) and is_l(b2) and is_a(b3) and is_s(b4) and is_s(b5) and b6 in ~c"_" and is_o(b7) and is_r(b8) and is_i(b9) and is_g(b10) and is_i(b11) and is_n(b12), do: {:non_reserved, :class_origin}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_c(b1) and is_o(b2) and is_b(b3) and is_o(b4) and is_l(b5), do: {:non_reserved, :cobol}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_c(b1) and is_o(b2) and is_l(b3) and is_l(b4) and is_a(b5) and is_t(b6) and is_i(b7) and is_o(b8) and is_n(b9), do: {:non_reserved, :collation}
  
  def tag([[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17]) when is_c(b1) and is_o(b2) and is_l(b3) and is_l(b4) and is_a(b5) and is_t(b6) and is_i(b7) and is_o(b8) and is_n(b9) and b10 in ~c"_" and is_c(b11) and is_a(b12) and is_t(b13) and is_a(b14) and is_l(b15) and is_o(b16) and is_g(b17), do: {:non_reserved, :collation_catalog}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_c(b1) and is_o(b2) and is_l(b3) and is_l(b4) and is_a(b5) and is_t(b6) and is_i(b7) and is_o(b8) and is_n(b9) and b10 in ~c"_" and is_n(b11) and is_a(b12) and is_m(b13) and is_e(b14), do: {:non_reserved, :collation_name}
  
  def tag([[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16]) when is_c(b1) and is_o(b2) and is_l(b3) and is_l(b4) and is_a(b5) and is_t(b6) and is_i(b7) and is_o(b8) and is_n(b9) and b10 in ~c"_" and is_s(b11) and is_c(b12) and is_h(b13) and is_e(b14) and is_m(b15) and is_a(b16), do: {:non_reserved, :collation_schema}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_c(b1) and is_o(b2) and is_l(b3) and is_u(b4) and is_m(b5) and is_n(b6) and is_s(b7), do: {:non_reserved, :columns}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_c(b1) and is_o(b2) and is_l(b3) and is_u(b4) and is_m(b5) and is_n(b6) and b7 in ~c"_" and is_n(b8) and is_a(b9) and is_m(b10) and is_e(b11), do: {:non_reserved, :column_name}
  
  def tag([[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16]) when is_c(b1) and is_o(b2) and is_m(b3) and is_m(b4) and is_a(b5) and is_n(b6) and is_d(b7) and b8 in ~c"_" and is_f(b9) and is_u(b10) and is_n(b11) and is_c(b12) and is_t(b13) and is_i(b14) and is_o(b15) and is_n(b16), do: {:non_reserved, :command_function}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21]) when is_c(b1) and is_o(b2) and is_m(b3) and is_m(b4) and is_a(b5) and is_n(b6) and is_d(b7) and b8 in ~c"_" and is_f(b9) and is_u(b10) and is_n(b11) and is_c(b12) and is_t(b13) and is_i(b14) and is_o(b15) and is_n(b16) and b17 in ~c"_" and is_c(b18) and is_o(b19) and is_d(b20) and is_e(b21), do: {:non_reserved, :command_function_code}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_c(b1) and is_o(b2) and is_m(b3) and is_m(b4) and is_i(b5) and is_t(b6) and is_t(b7) and is_e(b8) and is_d(b9), do: {:non_reserved, :committed}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_c(b1) and is_o(b2) and is_n(b3) and is_d(b4) and is_i(b5) and is_t(b6) and is_i(b7) and is_o(b8) and is_n(b9) and is_a(b10) and is_l(b11), do: {:non_reserved, :conditional}
  
  def tag([[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16]) when is_c(b1) and is_o(b2) and is_n(b3) and is_d(b4) and is_i(b5) and is_t(b6) and is_i(b7) and is_o(b8) and is_n(b9) and b10 in ~c"_" and is_n(b11) and is_u(b12) and is_m(b13) and is_b(b14) and is_e(b15) and is_r(b16), do: {:non_reserved, :condition_number}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_c(b1) and is_o(b2) and is_n(b3) and is_n(b4) and is_e(b5) and is_c(b6) and is_t(b7) and is_i(b8) and is_o(b9) and is_n(b10), do: {:non_reserved, :connection}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_c(b1) and is_o(b2) and is_n(b3) and is_n(b4) and is_e(b5) and is_c(b6) and is_t(b7) and is_i(b8) and is_o(b9) and is_n(b10) and b11 in ~c"_" and is_n(b12) and is_a(b13) and is_m(b14) and is_e(b15), do: {:non_reserved, :connection_name}
  
  def tag([[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18]) when is_c(b1) and is_o(b2) and is_n(b3) and is_s(b4) and is_t(b5) and is_r(b6) and is_a(b7) and is_i(b8) and is_n(b9) and is_t(b10) and b11 in ~c"_" and is_c(b12) and is_a(b13) and is_t(b14) and is_a(b15) and is_l(b16) and is_o(b17) and is_g(b18), do: {:non_reserved, :constraint_catalog}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_c(b1) and is_o(b2) and is_n(b3) and is_s(b4) and is_t(b5) and is_r(b6) and is_a(b7) and is_i(b8) and is_n(b9) and is_t(b10) and b11 in ~c"_" and is_n(b12) and is_a(b13) and is_m(b14) and is_e(b15), do: {:non_reserved, :constraint_name}
  
  def tag([[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17]) when is_c(b1) and is_o(b2) and is_n(b3) and is_s(b4) and is_t(b5) and is_r(b6) and is_a(b7) and is_i(b8) and is_n(b9) and is_t(b10) and b11 in ~c"_" and is_s(b12) and is_c(b13) and is_h(b14) and is_e(b15) and is_m(b16) and is_a(b17), do: {:non_reserved, :constraint_schema}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_c(b1) and is_o(b2) and is_n(b3) and is_s(b4) and is_t(b5) and is_r(b6) and is_a(b7) and is_i(b8) and is_n(b9) and is_t(b10) and is_s(b11), do: {:non_reserved, :constraints}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_c(b1) and is_o(b2) and is_n(b3) and is_s(b4) and is_t(b5) and is_r(b6) and is_u(b7) and is_c(b8) and is_t(b9) and is_o(b10) and is_r(b11), do: {:non_reserved, :constructor}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_c(b1) and is_o(b2) and is_n(b3) and is_t(b4) and is_i(b5) and is_n(b6) and is_u(b7) and is_e(b8), do: {:non_reserved, :continue}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_c(b1) and is_o(b2) and is_p(b3) and is_a(b4) and is_r(b5) and is_t(b6) and is_i(b7) and is_t(b8) and is_i(b9) and is_o(b10) and is_n(b11), do: {:non_reserved, :copartition}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_c(b1) and is_u(b2) and is_r(b3) and is_s(b4) and is_o(b5) and is_r(b6) and b7 in ~c"_" and is_n(b8) and is_a(b9) and is_m(b10) and is_e(b11), do: {:non_reserved, :cursor_name}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_d(b1) and is_a(b2) and is_t(b3) and is_a(b4), do: {:non_reserved, :data}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22]) when is_d(b1) and is_a(b2) and is_t(b3) and is_e(b4) and is_t(b5) and is_i(b6) and is_m(b7) and is_e(b8) and b9 in ~c"_" and is_i(b10) and is_n(b11) and is_t(b12) and is_e(b13) and is_r(b14) and is_v(b15) and is_a(b16) and is_l(b17) and b18 in ~c"_" and is_c(b19) and is_o(b20) and is_d(b21) and is_e(b22), do: {:non_reserved, :datetime_interval_code}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25], b26], b27]) when is_d(b1) and is_a(b2) and is_t(b3) and is_e(b4) and is_t(b5) and is_i(b6) and is_m(b7) and is_e(b8) and b9 in ~c"_" and is_i(b10) and is_n(b11) and is_t(b12) and is_e(b13) and is_r(b14) and is_v(b15) and is_a(b16) and is_l(b17) and b18 in ~c"_" and is_p(b19) and is_r(b20) and is_e(b21) and is_c(b22) and is_i(b23) and is_s(b24) and is_i(b25) and is_o(b26) and is_n(b27), do: {:non_reserved, :datetime_interval_precision}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_d(b1) and is_e(b2) and is_f(b3) and is_a(b4) and is_u(b5) and is_l(b6) and is_t(b7) and is_s(b8), do: {:non_reserved, :defaults}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_d(b1) and is_e(b2) and is_f(b3) and is_e(b4) and is_r(b5) and is_r(b6) and is_a(b7) and is_b(b8) and is_l(b9) and is_e(b10), do: {:non_reserved, :deferrable}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_d(b1) and is_e(b2) and is_f(b3) and is_e(b4) and is_r(b5) and is_r(b6) and is_e(b7) and is_d(b8), do: {:non_reserved, :deferred}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_d(b1) and is_e(b2) and is_f(b3) and is_i(b4) and is_n(b5) and is_e(b6) and is_d(b7), do: {:non_reserved, :defined}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_d(b1) and is_e(b2) and is_f(b3) and is_i(b4) and is_n(b5) and is_e(b6) and is_r(b7), do: {:non_reserved, :definer}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_d(b1) and is_e(b2) and is_g(b3) and is_r(b4) and is_e(b5) and is_e(b6), do: {:non_reserved, :degree}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_d(b1) and is_e(b2) and is_p(b3) and is_t(b4) and is_h(b5), do: {:non_reserved, :depth}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_d(b1) and is_e(b2) and is_r(b3) and is_i(b4) and is_v(b5) and is_e(b6) and is_d(b7), do: {:non_reserved, :derived}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_d(b1) and is_e(b2) and is_s(b3) and is_c(b4), do: {:non_reserved, :desc}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_d(b1) and is_e(b2) and is_s(b3) and is_c(b4) and is_r(b5) and is_i(b6) and is_p(b7) and is_t(b8) and is_o(b9) and is_r(b10), do: {:non_reserved, :descriptor}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_d(b1) and is_i(b2) and is_a(b3) and is_g(b4) and is_n(b5) and is_o(b6) and is_s(b7) and is_t(b8) and is_i(b9) and is_c(b10) and is_s(b11), do: {:non_reserved, :diagnostics}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_d(b1) and is_i(b2) and is_s(b3) and is_p(b4) and is_a(b5) and is_t(b6) and is_c(b7) and is_h(b8), do: {:non_reserved, :dispatch}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_d(b1) and is_o(b2) and is_m(b3) and is_a(b4) and is_i(b5) and is_n(b6), do: {:non_reserved, :domain}
  
  def tag([[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16]) when is_d(b1) and is_y(b2) and is_n(b3) and is_a(b4) and is_m(b5) and is_i(b6) and is_c(b7) and b8 in ~c"_" and is_f(b9) and is_u(b10) and is_n(b11) and is_c(b12) and is_t(b13) and is_i(b14) and is_o(b15) and is_n(b16), do: {:non_reserved, :dynamic_function}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21]) when is_d(b1) and is_y(b2) and is_n(b3) and is_a(b4) and is_m(b5) and is_i(b6) and is_c(b7) and b8 in ~c"_" and is_f(b9) and is_u(b10) and is_n(b11) and is_c(b12) and is_t(b13) and is_i(b14) and is_o(b15) and is_n(b16) and b17 in ~c"_" and is_c(b18) and is_o(b19) and is_d(b20) and is_e(b21), do: {:non_reserved, :dynamic_function_code}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_e(b1) and is_n(b2) and is_c(b3) and is_o(b4) and is_d(b5) and is_i(b6) and is_n(b7) and is_g(b8), do: {:non_reserved, :encoding}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_e(b1) and is_n(b2) and is_f(b3) and is_o(b4) and is_r(b5) and is_c(b6) and is_e(b7) and is_d(b8), do: {:non_reserved, :enforced}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_e(b1) and is_r(b2) and is_r(b3) and is_o(b4) and is_r(b5), do: {:non_reserved, :error}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_e(b1) and is_x(b2) and is_c(b3) and is_l(b4) and is_u(b5) and is_d(b6) and is_e(b7), do: {:non_reserved, :exclude}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_e(b1) and is_x(b2) and is_c(b3) and is_l(b4) and is_u(b5) and is_d(b6) and is_i(b7) and is_n(b8) and is_g(b9), do: {:non_reserved, :excluding}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_e(b1) and is_x(b2) and is_p(b3) and is_r(b4) and is_e(b5) and is_s(b6) and is_s(b7) and is_i(b8) and is_o(b9) and is_n(b10), do: {:non_reserved, :expression}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_f(b1) and is_i(b2) and is_n(b3) and is_a(b4) and is_l(b5), do: {:non_reserved, :final}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_f(b1) and is_i(b2) and is_n(b3) and is_i(b4) and is_s(b5) and is_h(b6), do: {:non_reserved, :finish}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_f(b1) and is_i(b2) and is_r(b3) and is_s(b4) and is_t(b5), do: {:non_reserved, :first}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_f(b1) and is_l(b2) and is_a(b3) and is_g(b4), do: {:non_reserved, :flag}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_f(b1) and is_o(b2) and is_l(b3) and is_l(b4) and is_o(b5) and is_w(b6) and is_i(b7) and is_n(b8) and is_g(b9), do: {:non_reserved, :following}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_f(b1) and is_o(b2) and is_r(b3) and is_m(b4) and is_a(b5) and is_t(b6), do: {:non_reserved, :format}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_f(b1) and is_o(b2) and is_r(b3) and is_t(b4) and is_r(b5) and is_a(b6) and is_n(b7), do: {:non_reserved, :fortran}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_f(b1) and is_o(b2) and is_u(b3) and is_n(b4) and is_d(b5), do: {:non_reserved, :found}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_f(b1) and is_u(b2) and is_l(b3) and is_f(b4) and is_i(b5) and is_l(b6) and is_l(b7), do: {:non_reserved, :fulfill}
  
  def tag([[], b1]) when is_g(b1), do: {:non_reserved, :g}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_g(b1) and is_e(b2) and is_n(b3) and is_e(b4) and is_r(b5) and is_a(b6) and is_l(b7), do: {:non_reserved, :general}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_g(b1) and is_e(b2) and is_n(b3) and is_e(b4) and is_r(b5) and is_a(b6) and is_t(b7) and is_e(b8) and is_d(b9), do: {:non_reserved, :generated}
  
  def tag([[[], b1], b2]) when is_g(b1) and is_o(b2), do: {:non_reserved, :go}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_g(b1) and is_o(b2) and is_t(b3) and is_o(b4), do: {:non_reserved, :goto}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_g(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_t(b5) and is_e(b6) and is_d(b7), do: {:non_reserved, :granted}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_h(b1) and is_i(b2) and is_e(b3) and is_r(b4) and is_a(b5) and is_r(b6) and is_c(b7) and is_h(b8) and is_y(b9), do: {:non_reserved, :hierarchy}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_i(b1) and is_g(b2) and is_n(b3) and is_o(b4) and is_r(b5) and is_e(b6), do: {:non_reserved, :ignore}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_i(b1) and is_m(b2) and is_m(b3) and is_e(b4) and is_d(b5) and is_i(b6) and is_a(b7) and is_t(b8) and is_e(b9), do: {:non_reserved, :immediate}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_i(b1) and is_m(b2) and is_m(b3) and is_e(b4) and is_d(b5) and is_i(b6) and is_a(b7) and is_t(b8) and is_e(b9) and is_l(b10) and is_y(b11), do: {:non_reserved, :immediately}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_i(b1) and is_m(b2) and is_p(b3) and is_l(b4) and is_e(b5) and is_m(b6) and is_e(b7) and is_n(b8) and is_t(b9) and is_a(b10) and is_t(b11) and is_i(b12) and is_o(b13) and is_n(b14), do: {:non_reserved, :implementation}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_i(b1) and is_n(b2) and is_c(b3) and is_l(b4) and is_u(b5) and is_d(b6) and is_i(b7) and is_n(b8) and is_g(b9), do: {:non_reserved, :including}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_i(b1) and is_n(b2) and is_c(b3) and is_r(b4) and is_e(b5) and is_m(b6) and is_e(b7) and is_n(b8) and is_t(b9), do: {:non_reserved, :increment}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_i(b1) and is_n(b2) and is_i(b3) and is_t(b4) and is_i(b5) and is_a(b6) and is_l(b7) and is_l(b8) and is_y(b9), do: {:non_reserved, :initially}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_i(b1) and is_n(b2) and is_p(b3) and is_u(b4) and is_t(b5), do: {:non_reserved, :input}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_i(b1) and is_n(b2) and is_s(b3) and is_t(b4) and is_a(b5) and is_n(b6) and is_c(b7) and is_e(b8), do: {:non_reserved, :instance}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_i(b1) and is_n(b2) and is_s(b3) and is_t(b4) and is_a(b5) and is_n(b6) and is_t(b7) and is_i(b8) and is_a(b9) and is_b(b10) and is_l(b11) and is_e(b12), do: {:non_reserved, :instantiable}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_i(b1) and is_n(b2) and is_s(b3) and is_t(b4) and is_e(b5) and is_a(b6) and is_d(b7), do: {:non_reserved, :instead}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_i(b1) and is_n(b2) and is_v(b3) and is_o(b4) and is_k(b5) and is_e(b6) and is_r(b7), do: {:non_reserved, :invoker}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_i(b1) and is_s(b2) and is_o(b3) and is_l(b4) and is_a(b5) and is_t(b6) and is_i(b7) and is_o(b8) and is_n(b9), do: {:non_reserved, :isolation}
  
  def tag([[], b1]) when is_k(b1), do: {:non_reserved, :k}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_k(b1) and is_e(b2) and is_e(b3) and is_p(b4), do: {:non_reserved, :keep}
  
  def tag([[[[], b1], b2], b3]) when is_k(b1) and is_e(b2) and is_y(b3), do: {:non_reserved, :key}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_k(b1) and is_e(b2) and is_y(b3) and is_s(b4), do: {:non_reserved, :keys}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_k(b1) and is_e(b2) and is_y(b3) and b4 in ~c"_" and is_m(b5) and is_e(b6) and is_m(b7) and is_b(b8) and is_e(b9) and is_r(b10), do: {:non_reserved, :key_member}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_k(b1) and is_e(b2) and is_y(b3) and b4 in ~c"_" and is_t(b5) and is_y(b6) and is_p(b7) and is_e(b8), do: {:non_reserved, :key_type}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_l(b1) and is_a(b2) and is_s(b3) and is_t(b4), do: {:non_reserved, :last}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_l(b1) and is_e(b2) and is_n(b3) and is_g(b4) and is_t(b5) and is_h(b6), do: {:non_reserved, :length}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_l(b1) and is_e(b2) and is_v(b3) and is_e(b4) and is_l(b5), do: {:non_reserved, :level}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_l(b1) and is_o(b2) and is_c(b3) and is_a(b4) and is_t(b5) and is_o(b6) and is_r(b7), do: {:non_reserved, :locator}
  
  def tag([[], b1]) when is_m(b1), do: {:non_reserved, :m}
  
  def tag([[[[], b1], b2], b3]) when is_m(b1) and is_a(b2) and is_p(b3), do: {:non_reserved, :map}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_m(b1) and is_a(b2) and is_t(b3) and is_c(b4) and is_h(b5) and is_e(b6) and is_d(b7), do: {:non_reserved, :matched}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_m(b1) and is_a(b2) and is_x(b3) and is_v(b4) and is_a(b5) and is_l(b6) and is_u(b7) and is_e(b8), do: {:non_reserved, :maxvalue}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_m(b1) and is_e(b2) and is_a(b3) and is_s(b4) and is_u(b5) and is_r(b6) and is_e(b7) and is_s(b8), do: {:non_reserved, :measures}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_m(b1) and is_e(b2) and is_s(b3) and is_s(b4) and is_a(b5) and is_g(b6) and is_e(b7) and b8 in ~c"_" and is_l(b9) and is_e(b10) and is_n(b11) and is_g(b12) and is_t(b13) and is_h(b14), do: {:non_reserved, :message_length}
  
  def tag([[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20]) when is_m(b1) and is_e(b2) and is_s(b3) and is_s(b4) and is_a(b5) and is_g(b6) and is_e(b7) and b8 in ~c"_" and is_o(b9) and is_c(b10) and is_t(b11) and is_e(b12) and is_t(b13) and b14 in ~c"_" and is_l(b15) and is_e(b16) and is_n(b17) and is_g(b18) and is_t(b19) and is_h(b20), do: {:non_reserved, :message_octet_length}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_m(b1) and is_e(b2) and is_s(b3) and is_s(b4) and is_a(b5) and is_g(b6) and is_e(b7) and b8 in ~c"_" and is_t(b9) and is_e(b10) and is_x(b11) and is_t(b12), do: {:non_reserved, :message_text}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_m(b1) and is_i(b2) and is_n(b3) and is_v(b4) and is_a(b5) and is_l(b6) and is_u(b7) and is_e(b8), do: {:non_reserved, :minvalue}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_m(b1) and is_o(b2) and is_r(b3) and is_e(b4), do: {:non_reserved, :more}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_m(b1) and is_u(b2) and is_m(b3) and is_p(b4) and is_s(b5), do: {:non_reserved, :mumps}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_n(b1) and is_a(b2) and is_m(b3) and is_e(b4), do: {:non_reserved, :name}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_n(b1) and is_a(b2) and is_m(b3) and is_e(b4) and is_s(b5), do: {:non_reserved, :names}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_n(b1) and is_e(b2) and is_s(b3) and is_t(b4) and is_e(b5) and is_d(b6), do: {:non_reserved, :nested}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_n(b1) and is_e(b2) and is_s(b3) and is_t(b4) and is_i(b5) and is_n(b6) and is_g(b7), do: {:non_reserved, :nesting}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_n(b1) and is_e(b2) and is_x(b3) and is_t(b4), do: {:non_reserved, :next}
  
  def tag([[[[], b1], b2], b3]) when is_n(b1) and is_f(b2) and is_c(b3), do: {:non_reserved, :nfc}
  
  def tag([[[[], b1], b2], b3]) when is_n(b1) and is_f(b2) and is_d(b3), do: {:non_reserved, :nfd}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_n(b1) and is_f(b2) and is_k(b3) and is_c(b4), do: {:non_reserved, :nfkc}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_n(b1) and is_f(b2) and is_k(b3) and is_d(b4), do: {:non_reserved, :nfkd}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_n(b1) and is_o(b2) and is_r(b3) and is_m(b4) and is_a(b5) and is_l(b6) and is_i(b7) and is_z(b8) and is_e(b9) and is_d(b10), do: {:non_reserved, :normalized}
  
  def tag([[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when is_n(b1) and is_u(b2) and is_l(b3) and is_l(b4) and b5 in ~c"_" and is_o(b6) and is_r(b7) and is_d(b8) and is_e(b9) and is_r(b10) and is_i(b11) and is_n(b12) and is_g(b13), do: {:non_reserved, :null_ordering}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_n(b1) and is_u(b2) and is_l(b3) and is_l(b4) and is_a(b5) and is_b(b6) and is_l(b7) and is_e(b8), do: {:non_reserved, :nullable}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_n(b1) and is_u(b2) and is_l(b3) and is_l(b4) and is_s(b5), do: {:non_reserved, :nulls}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_n(b1) and is_u(b2) and is_m(b3) and is_b(b4) and is_e(b5) and is_r(b6), do: {:non_reserved, :number}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_o(b1) and is_b(b2) and is_j(b3) and is_e(b4) and is_c(b5) and is_t(b6), do: {:non_reserved, :object}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_o(b1) and is_c(b2) and is_c(b3) and is_u(b4) and is_r(b5) and is_r(b6) and is_e(b7) and is_n(b8) and is_c(b9) and is_e(b10), do: {:non_reserved, :occurrence}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_o(b1) and is_c(b2) and is_t(b3) and is_e(b4) and is_t(b5) and is_s(b6), do: {:non_reserved, :octets}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_o(b1) and is_p(b2) and is_t(b3) and is_i(b4) and is_o(b5) and is_n(b6), do: {:non_reserved, :option}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_o(b1) and is_p(b2) and is_t(b3) and is_i(b4) and is_o(b5) and is_n(b6) and is_s(b7), do: {:non_reserved, :options}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_o(b1) and is_r(b2) and is_d(b3) and is_e(b4) and is_r(b5) and is_i(b6) and is_n(b7) and is_g(b8), do: {:non_reserved, :ordering}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_o(b1) and is_r(b2) and is_d(b3) and is_i(b4) and is_n(b5) and is_a(b6) and is_l(b7) and is_i(b8) and is_t(b9) and is_y(b10), do: {:non_reserved, :ordinality}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_o(b1) and is_t(b2) and is_h(b3) and is_e(b4) and is_r(b5) and is_s(b6), do: {:non_reserved, :others}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_o(b1) and is_u(b2) and is_t(b3) and is_p(b4) and is_u(b5) and is_t(b6), do: {:non_reserved, :output}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_o(b1) and is_v(b2) and is_e(b3) and is_r(b4) and is_f(b5) and is_l(b6) and is_o(b7) and is_w(b8), do: {:non_reserved, :overflow}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_o(b1) and is_v(b2) and is_e(b3) and is_r(b4) and is_r(b5) and is_i(b6) and is_d(b7) and is_i(b8) and is_n(b9) and is_g(b10), do: {:non_reserved, :overriding}
  
  def tag([[], b1]) when is_p(b1), do: {:non_reserved, :p}
  
  def tag([[[[], b1], b2], b3]) when is_p(b1) and is_a(b2) and is_d(b3), do: {:non_reserved, :pad}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_p(b1) and is_a(b2) and is_r(b3) and is_a(b4) and is_m(b5) and is_e(b6) and is_t(b7) and is_e(b8) and is_r(b9) and b10 in ~c"_" and is_m(b11) and is_o(b12) and is_d(b13) and is_e(b14), do: {:non_reserved, :parameter_mode}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_p(b1) and is_a(b2) and is_r(b3) and is_a(b4) and is_m(b5) and is_e(b6) and is_t(b7) and is_e(b8) and is_r(b9) and b10 in ~c"_" and is_n(b11) and is_a(b12) and is_m(b13) and is_e(b14), do: {:non_reserved, :parameter_name}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25], b26]) when is_p(b1) and is_a(b2) and is_r(b3) and is_a(b4) and is_m(b5) and is_e(b6) and is_t(b7) and is_e(b8) and is_r(b9) and b10 in ~c"_" and is_o(b11) and is_r(b12) and is_d(b13) and is_i(b14) and is_n(b15) and is_a(b16) and is_l(b17) and b18 in ~c"_" and is_p(b19) and is_o(b20) and is_s(b21) and is_i(b22) and is_t(b23) and is_i(b24) and is_o(b25) and is_n(b26), do: {:non_reserved, :parameter_ordinal_position}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25], b26]) when is_p(b1) and is_a(b2) and is_r(b3) and is_a(b4) and is_m(b5) and is_e(b6) and is_t(b7) and is_e(b8) and is_r(b9) and b10 in ~c"_" and is_s(b11) and is_p(b12) and is_e(b13) and is_c(b14) and is_i(b15) and is_f(b16) and is_i(b17) and is_c(b18) and b19 in ~c"_" and is_c(b20) and is_a(b21) and is_t(b22) and is_a(b23) and is_l(b24) and is_o(b25) and is_g(b26), do: {:non_reserved, :parameter_specific_catalog}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23]) when is_p(b1) and is_a(b2) and is_r(b3) and is_a(b4) and is_m(b5) and is_e(b6) and is_t(b7) and is_e(b8) and is_r(b9) and b10 in ~c"_" and is_s(b11) and is_p(b12) and is_e(b13) and is_c(b14) and is_i(b15) and is_f(b16) and is_i(b17) and is_c(b18) and b19 in ~c"_" and is_n(b20) and is_a(b21) and is_m(b22) and is_e(b23), do: {:non_reserved, :parameter_specific_name}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25]) when is_p(b1) and is_a(b2) and is_r(b3) and is_a(b4) and is_m(b5) and is_e(b6) and is_t(b7) and is_e(b8) and is_r(b9) and b10 in ~c"_" and is_s(b11) and is_p(b12) and is_e(b13) and is_c(b14) and is_i(b15) and is_f(b16) and is_i(b17) and is_c(b18) and b19 in ~c"_" and is_s(b20) and is_c(b21) and is_h(b22) and is_e(b23) and is_m(b24) and is_a(b25), do: {:non_reserved, :parameter_specific_schema}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_p(b1) and is_a(b2) and is_r(b3) and is_t(b4) and is_i(b5) and is_a(b6) and is_l(b7), do: {:non_reserved, :partial}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_p(b1) and is_a(b2) and is_s(b3) and is_c(b4) and is_a(b5) and is_l(b6), do: {:non_reserved, :pascal}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_p(b1) and is_a(b2) and is_s(b3) and is_s(b4), do: {:non_reserved, :pass}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_p(b1) and is_a(b2) and is_s(b3) and is_s(b4) and is_i(b5) and is_n(b6) and is_g(b7), do: {:non_reserved, :passing}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_p(b1) and is_a(b2) and is_s(b3) and is_t(b4), do: {:non_reserved, :past}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_p(b1) and is_a(b2) and is_t(b3) and is_h(b4), do: {:non_reserved, :path}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_p(b1) and is_e(b2) and is_r(b3) and is_m(b4) and is_u(b5) and is_t(b6) and is_e(b7), do: {:non_reserved, :permute}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_p(b1) and is_i(b2) and is_p(b3) and is_e(b4), do: {:non_reserved, :pipe}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_p(b1) and is_l(b2) and is_a(b3) and is_c(b4) and is_i(b5) and is_n(b6) and is_g(b7), do: {:non_reserved, :placing}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_p(b1) and is_l(b2) and is_a(b3) and is_n(b4), do: {:non_reserved, :plan}
  
  def tag([[[[], b1], b2], b3]) when is_p(b1) and is_l(b2) and is_i(b3), do: {:non_reserved, :pli}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_p(b1) and is_r(b2) and is_e(b3) and is_c(b4) and is_e(b5) and is_d(b6) and is_i(b7) and is_n(b8) and is_g(b9), do: {:non_reserved, :preceding}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_p(b1) and is_r(b2) and is_e(b3) and is_s(b4) and is_e(b5) and is_r(b6) and is_v(b7) and is_e(b8), do: {:non_reserved, :preserve}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_p(b1) and is_r(b2) and is_e(b3) and is_v(b4), do: {:non_reserved, :prev}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_p(b1) and is_r(b2) and is_i(b3) and is_o(b4) and is_r(b5), do: {:non_reserved, :prior}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_p(b1) and is_r(b2) and is_i(b3) and is_v(b4) and is_a(b5) and is_t(b6) and is_e(b7), do: {:non_reserved, :private}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_p(b1) and is_r(b2) and is_i(b3) and is_v(b4) and is_i(b5) and is_l(b6) and is_e(b7) and is_g(b8) and is_e(b9) and is_s(b10), do: {:non_reserved, :privileges}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_p(b1) and is_r(b2) and is_u(b3) and is_n(b4) and is_e(b5), do: {:non_reserved, :prune}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_p(b1) and is_u(b2) and is_b(b3) and is_l(b4) and is_i(b5) and is_c(b6), do: {:non_reserved, :public}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_q(b1) and is_u(b2) and is_o(b3) and is_t(b4) and is_e(b5) and is_s(b6), do: {:non_reserved, :quotes}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_r(b1) and is_e(b2) and is_a(b3) and is_d(b4), do: {:non_reserved, :read}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_r(b1) and is_e(b2) and is_l(b3) and is_a(b4) and is_t(b5) and is_i(b6) and is_v(b7) and is_e(b8), do: {:non_reserved, :relative}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_r(b1) and is_e(b2) and is_p(b3) and is_e(b4) and is_a(b5) and is_t(b6) and is_a(b7) and is_b(b8) and is_l(b9) and is_e(b10), do: {:non_reserved, :repeatable}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_r(b1) and is_e(b2) and is_s(b3) and is_p(b4) and is_e(b5) and is_c(b6) and is_t(b7), do: {:non_reserved, :respect}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_r(b1) and is_e(b2) and is_s(b3) and is_t(b4) and is_a(b5) and is_r(b6) and is_t(b7), do: {:non_reserved, :restart}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_r(b1) and is_e(b2) and is_s(b3) and is_t(b4) and is_r(b5) and is_i(b6) and is_c(b7) and is_t(b8), do: {:non_reserved, :restrict}
  
  def tag([[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20]) when is_r(b1) and is_e(b2) and is_t(b3) and is_u(b4) and is_r(b5) and is_n(b6) and is_e(b7) and is_d(b8) and b9 in ~c"_" and is_c(b10) and is_a(b11) and is_r(b12) and is_d(b13) and is_i(b14) and is_n(b15) and is_a(b16) and is_l(b17) and is_i(b18) and is_t(b19) and is_y(b20), do: {:non_reserved, :returned_cardinality}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_r(b1) and is_e(b2) and is_t(b3) and is_u(b4) and is_r(b5) and is_n(b6) and is_e(b7) and is_d(b8) and b9 in ~c"_" and is_l(b10) and is_e(b11) and is_n(b12) and is_g(b13) and is_t(b14) and is_h(b15), do: {:non_reserved, :returned_length}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21]) when is_r(b1) and is_e(b2) and is_t(b3) and is_u(b4) and is_r(b5) and is_n(b6) and is_e(b7) and is_d(b8) and b9 in ~c"_" and is_o(b10) and is_c(b11) and is_t(b12) and is_e(b13) and is_t(b14) and b15 in ~c"_" and is_l(b16) and is_e(b17) and is_n(b18) and is_g(b19) and is_t(b20) and is_h(b21), do: {:non_reserved, :returned_octet_length}
  
  def tag([[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17]) when is_r(b1) and is_e(b2) and is_t(b3) and is_u(b4) and is_r(b5) and is_n(b6) and is_e(b7) and is_d(b8) and b9 in ~c"_" and is_s(b10) and is_q(b11) and is_l(b12) and is_s(b13) and is_t(b14) and is_a(b15) and is_t(b16) and is_e(b17), do: {:non_reserved, :returned_sqlstate}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_r(b1) and is_e(b2) and is_t(b3) and is_u(b4) and is_r(b5) and is_n(b6) and is_i(b7) and is_n(b8) and is_g(b9), do: {:non_reserved, :returning}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_r(b1) and is_o(b2) and is_l(b3) and is_e(b4), do: {:non_reserved, :role}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_r(b1) and is_o(b2) and is_u(b3) and is_t(b4) and is_i(b5) and is_n(b6) and is_e(b7), do: {:non_reserved, :routine}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_r(b1) and is_o(b2) and is_u(b3) and is_t(b4) and is_i(b5) and is_n(b6) and is_e(b7) and b8 in ~c"_" and is_c(b9) and is_a(b10) and is_t(b11) and is_a(b12) and is_l(b13) and is_o(b14) and is_g(b15), do: {:non_reserved, :routine_catalog}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_r(b1) and is_o(b2) and is_u(b3) and is_t(b4) and is_i(b5) and is_n(b6) and is_e(b7) and b8 in ~c"_" and is_n(b9) and is_a(b10) and is_m(b11) and is_e(b12), do: {:non_reserved, :routine_name}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_r(b1) and is_o(b2) and is_u(b3) and is_t(b4) and is_i(b5) and is_n(b6) and is_e(b7) and b8 in ~c"_" and is_s(b9) and is_c(b10) and is_h(b11) and is_e(b12) and is_m(b13) and is_a(b14), do: {:non_reserved, :routine_schema}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_r(b1) and is_o(b2) and is_w(b3) and b4 in ~c"_" and is_c(b5) and is_o(b6) and is_u(b7) and is_n(b8) and is_t(b9), do: {:non_reserved, :row_count}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_c(b2) and is_a(b3) and is_l(b4) and is_a(b5) and is_r(b6), do: {:non_reserved, :scalar}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_s(b1) and is_c(b2) and is_a(b3) and is_l(b4) and is_e(b5), do: {:non_reserved, :scale}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_c(b2) and is_h(b3) and is_e(b4) and is_m(b5) and is_a(b6), do: {:non_reserved, :schema}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_s(b1) and is_c(b2) and is_h(b3) and is_e(b4) and is_m(b5) and is_a(b6) and b7 in ~c"_" and is_n(b8) and is_a(b9) and is_m(b10) and is_e(b11), do: {:non_reserved, :schema_name}
  
  def tag([[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when is_s(b1) and is_c(b2) and is_o(b3) and is_p(b4) and is_e(b5) and b6 in ~c"_" and is_c(b7) and is_a(b8) and is_t(b9) and is_a(b10) and is_l(b11) and is_o(b12) and is_g(b13), do: {:non_reserved, :scope_catalog}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_s(b1) and is_c(b2) and is_o(b3) and is_p(b4) and is_e(b5) and b6 in ~c"_" and is_n(b7) and is_a(b8) and is_m(b9) and is_e(b10), do: {:non_reserved, :scope_name}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_s(b1) and is_c(b2) and is_o(b3) and is_p(b4) and is_e(b5) and b6 in ~c"_" and is_s(b7) and is_c(b8) and is_h(b9) and is_e(b10) and is_m(b11) and is_a(b12), do: {:non_reserved, :scope_schema}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_s(b1) and is_e(b2) and is_c(b3) and is_t(b4) and is_i(b5) and is_o(b6) and is_n(b7), do: {:non_reserved, :section}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_s(b1) and is_e(b2) and is_c(b3) and is_u(b4) and is_r(b5) and is_i(b6) and is_t(b7) and is_y(b8), do: {:non_reserved, :security}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_s(b1) and is_e(b2) and is_l(b3) and is_f(b4), do: {:non_reserved, :self}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_s(b1) and is_e(b2) and is_m(b3) and is_a(b4) and is_n(b5) and is_t(b6) and is_i(b7) and is_c(b8) and is_s(b9), do: {:non_reserved, :semantics}
  
  def tag([[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8]) when is_s(b1) and is_e(b2) and is_q(b3) and is_u(b4) and is_e(b5) and is_n(b6) and is_c(b7) and is_e(b8), do: {:non_reserved, :sequence}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_s(b1) and is_e(b2) and is_r(b3) and is_i(b4) and is_a(b5) and is_l(b6) and is_i(b7) and is_z(b8) and is_a(b9) and is_b(b10) and is_l(b11) and is_e(b12), do: {:non_reserved, :serializable}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_s(b1) and is_e(b2) and is_r(b3) and is_v(b4) and is_e(b5) and is_r(b6) and b7 in ~c"_" and is_n(b8) and is_a(b9) and is_m(b10) and is_e(b11), do: {:non_reserved, :server_name}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_s(b1) and is_e(b2) and is_s(b3) and is_s(b4) and is_i(b5) and is_o(b6) and is_n(b7), do: {:non_reserved, :session}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_s(b1) and is_e(b2) and is_t(b3) and is_s(b4), do: {:non_reserved, :sets}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_i(b2) and is_m(b3) and is_p(b4) and is_l(b5) and is_e(b6), do: {:non_reserved, :simple}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_s(b1) and is_i(b2) and is_z(b3) and is_e(b4), do: {:non_reserved, :size}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_s(b1) and is_o(b2) and is_r(b3) and is_t(b4) and b5 in ~c"_" and is_d(b6) and is_i(b7) and is_r(b8) and is_e(b9) and is_c(b10) and is_t(b11) and is_i(b12) and is_o(b13) and is_n(b14), do: {:non_reserved, :sort_direction}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_o(b2) and is_u(b3) and is_r(b4) and is_c(b5) and is_e(b6), do: {:non_reserved, :source}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_s(b1) and is_p(b2) and is_a(b3) and is_c(b4) and is_e(b5), do: {:non_reserved, :space}
  
  def tag([[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when is_s(b1) and is_p(b2) and is_e(b3) and is_c(b4) and is_i(b5) and is_f(b6) and is_i(b7) and is_c(b8) and b9 in ~c"_" and is_n(b10) and is_a(b11) and is_m(b12) and is_e(b13), do: {:non_reserved, :specific_name}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_s(b1) and is_t(b2) and is_a(b3) and is_t(b4) and is_e(b5), do: {:non_reserved, :state}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_s(b1) and is_t(b2) and is_a(b3) and is_t(b4) and is_e(b5) and is_m(b6) and is_e(b7) and is_n(b8) and is_t(b9), do: {:non_reserved, :statement}
  
  def tag([[[[[[[], b1], b2], b3], b4], b5], b6]) when is_s(b1) and is_t(b2) and is_r(b3) and is_i(b4) and is_n(b5) and is_g(b6), do: {:non_reserved, :string}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_s(b1) and is_t(b2) and is_r(b3) and is_u(b4) and is_c(b5) and is_t(b6) and is_u(b7) and is_r(b8) and is_e(b9), do: {:non_reserved, :structure}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_s(b1) and is_t(b2) and is_y(b3) and is_l(b4) and is_e(b5), do: {:non_reserved, :style}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_s(b1) and is_u(b2) and is_b(b3) and is_c(b4) and is_l(b5) and is_a(b6) and is_s(b7) and is_s(b8) and b9 in ~c"_" and is_o(b10) and is_r(b11) and is_i(b12) and is_g(b13) and is_i(b14) and is_n(b15), do: {:non_reserved, :subclass_origin}
  
  def tag([[], b1]) when is_t(b1), do: {:non_reserved, :t}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_t(b1) and is_a(b2) and is_b(b3) and is_l(b4) and is_e(b5) and b6 in ~c"_" and is_n(b7) and is_a(b8) and is_m(b9) and is_e(b10), do: {:non_reserved, :table_name}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_t(b1) and is_e(b2) and is_m(b3) and is_p(b4) and is_o(b5) and is_r(b6) and is_a(b7) and is_r(b8) and is_y(b9), do: {:non_reserved, :temporary}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_t(b1) and is_h(b2) and is_r(b3) and is_o(b4) and is_u(b5) and is_g(b6) and is_h(b7), do: {:non_reserved, :through}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_t(b1) and is_i(b2) and is_e(b3) and is_s(b4), do: {:non_reserved, :ties}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_t(b1) and is_o(b2) and is_p(b3) and b4 in ~c"_" and is_l(b5) and is_e(b6) and is_v(b7) and is_e(b8) and is_l(b9) and b10 in ~c"_" and is_c(b11) and is_o(b12) and is_u(b13) and is_n(b14) and is_t(b15), do: {:non_reserved, :top_level_count}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_t(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_s(b5) and is_a(b6) and is_c(b7) and is_t(b8) and is_i(b9) and is_o(b10) and is_n(b11), do: {:non_reserved, :transaction}
  
  def tag([[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18]) when is_t(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_s(b5) and is_a(b6) and is_c(b7) and is_t(b8) and is_i(b9) and is_o(b10) and is_n(b11) and b12 in ~c"_" and is_a(b13) and is_c(b14) and is_t(b15) and is_i(b16) and is_v(b17) and is_e(b18), do: {:non_reserved, :transaction_active}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22]) when is_t(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_s(b5) and is_a(b6) and is_c(b7) and is_t(b8) and is_i(b9) and is_o(b10) and is_n(b11) and is_s(b12) and b13 in ~c"_" and is_c(b14) and is_o(b15) and is_m(b16) and is_m(b17) and is_i(b18) and is_t(b19) and is_t(b20) and is_e(b21) and is_d(b22), do: {:non_reserved, :transactions_committed}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24]) when is_t(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_s(b5) and is_a(b6) and is_c(b7) and is_t(b8) and is_i(b9) and is_o(b10) and is_n(b11) and is_s(b12) and b13 in ~c"_" and is_r(b14) and is_o(b15) and is_l(b16) and is_l(b17) and is_e(b18) and is_d(b19) and b20 in ~c"_" and is_b(b21) and is_a(b22) and is_c(b23) and is_k(b24), do: {:non_reserved, :transactions_rolled_back}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_t(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_s(b5) and is_f(b6) and is_o(b7) and is_r(b8) and is_m(b9), do: {:non_reserved, :transform}
  
  def tag([[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10]) when is_t(b1) and is_r(b2) and is_a(b3) and is_n(b4) and is_s(b5) and is_f(b6) and is_o(b7) and is_r(b8) and is_m(b9) and is_s(b10), do: {:non_reserved, :transforms}
  
  def tag([[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15]) when is_t(b1) and is_r(b2) and is_i(b3) and is_g(b4) and is_g(b5) and is_e(b6) and is_r(b7) and b8 in ~c"_" and is_c(b9) and is_a(b10) and is_t(b11) and is_a(b12) and is_l(b13) and is_o(b14) and is_g(b15), do: {:non_reserved, :trigger_catalog}
  
  def tag([[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12]) when is_t(b1) and is_r(b2) and is_i(b3) and is_g(b4) and is_g(b5) and is_e(b6) and is_r(b7) and b8 in ~c"_" and is_n(b9) and is_a(b10) and is_m(b11) and is_e(b12), do: {:non_reserved, :trigger_name}
  
  def tag([[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14]) when is_t(b1) and is_r(b2) and is_i(b3) and is_g(b4) and is_g(b5) and is_e(b6) and is_r(b7) and b8 in ~c"_" and is_s(b9) and is_c(b10) and is_h(b11) and is_e(b12) and is_m(b13) and is_a(b14), do: {:non_reserved, :trigger_schema}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_t(b1) and is_y(b2) and is_p(b3) and is_e(b4), do: {:non_reserved, :type}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_u(b1) and is_n(b2) and is_b(b3) and is_o(b4) and is_u(b5) and is_n(b6) and is_d(b7) and is_e(b8) and is_d(b9), do: {:non_reserved, :unbounded}
  
  def tag([[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11]) when is_u(b1) and is_n(b2) and is_c(b3) and is_o(b4) and is_m(b5) and is_m(b6) and is_i(b7) and is_t(b8) and is_t(b9) and is_e(b10) and is_d(b11), do: {:non_reserved, :uncommitted}
  
  def tag([[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13]) when is_u(b1) and is_n(b2) and is_c(b3) and is_o(b4) and is_n(b5) and is_d(b6) and is_i(b7) and is_t(b8) and is_i(b9) and is_o(b10) and is_n(b11) and is_a(b12) and is_l(b13), do: {:non_reserved, :unconditional}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_u(b1) and is_n(b2) and is_d(b3) and is_e(b4) and is_r(b5), do: {:non_reserved, :under}
  
  def tag([[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9]) when is_u(b1) and is_n(b2) and is_m(b3) and is_a(b4) and is_t(b5) and is_c(b6) and is_h(b7) and is_e(b8) and is_d(b9), do: {:non_reserved, :unmatched}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_u(b1) and is_n(b2) and is_n(b3) and is_a(b4) and is_m(b5) and is_e(b6) and is_d(b7), do: {:non_reserved, :unnamed}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_u(b1) and is_s(b2) and is_a(b3) and is_g(b4) and is_e(b5), do: {:non_reserved, :usage}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24], b25]) when is_u(b1) and is_s(b2) and is_e(b3) and is_r(b4) and b5 in ~c"_" and is_d(b6) and is_e(b7) and is_f(b8) and is_i(b9) and is_n(b10) and is_e(b11) and is_d(b12) and b13 in ~c"_" and is_t(b14) and is_y(b15) and is_p(b16) and is_e(b17) and b18 in ~c"_" and is_c(b19) and is_a(b20) and is_t(b21) and is_a(b22) and is_l(b23) and is_o(b24) and is_g(b25), do: {:non_reserved, :user_defined_type_catalog}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22]) when is_u(b1) and is_s(b2) and is_e(b3) and is_r(b4) and b5 in ~c"_" and is_d(b6) and is_e(b7) and is_f(b8) and is_i(b9) and is_n(b10) and is_e(b11) and is_d(b12) and b13 in ~c"_" and is_t(b14) and is_y(b15) and is_p(b16) and is_e(b17) and b18 in ~c"_" and is_c(b19) and is_o(b20) and is_d(b21) and is_e(b22), do: {:non_reserved, :user_defined_type_code}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22]) when is_u(b1) and is_s(b2) and is_e(b3) and is_r(b4) and b5 in ~c"_" and is_d(b6) and is_e(b7) and is_f(b8) and is_i(b9) and is_n(b10) and is_e(b11) and is_d(b12) and b13 in ~c"_" and is_t(b14) and is_y(b15) and is_p(b16) and is_e(b17) and b18 in ~c"_" and is_n(b19) and is_a(b20) and is_m(b21) and is_e(b22), do: {:non_reserved, :user_defined_type_name}
  
  def tag([[[[[[[[[[[[[[[[[[[[[[[[[], b1], b2], b3], b4], b5], b6], b7], b8], b9], b10], b11], b12], b13], b14], b15], b16], b17], b18], b19], b20], b21], b22], b23], b24]) when is_u(b1) and is_s(b2) and is_e(b3) and is_r(b4) and b5 in ~c"_" and is_d(b6) and is_e(b7) and is_f(b8) and is_i(b9) and is_n(b10) and is_e(b11) and is_d(b12) and b13 in ~c"_" and is_t(b14) and is_y(b15) and is_p(b16) and is_e(b17) and b18 in ~c"_" and is_s(b19) and is_c(b20) and is_h(b21) and is_e(b22) and is_m(b23) and is_a(b24), do: {:non_reserved, :user_defined_type_schema}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_u(b1) and is_t(b2) and is_f(b3) and b4 in ~c"1" and b5 in ~c"6", do: {:non_reserved, :utf16}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_u(b1) and is_t(b2) and is_f(b3) and b4 in ~c"3" and b5 in ~c"2", do: {:non_reserved, :utf32}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_u(b1) and is_t(b2) and is_f(b3) and b4 in ~c"8", do: {:non_reserved, :utf8}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_v(b1) and is_i(b2) and is_e(b3) and is_w(b4), do: {:non_reserved, :view}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_w(b1) and is_o(b2) and is_r(b3) and is_k(b4), do: {:non_reserved, :work}
  
  def tag([[[[[[[[], b1], b2], b3], b4], b5], b6], b7]) when is_w(b1) and is_r(b2) and is_a(b3) and is_p(b4) and is_p(b5) and is_e(b6) and is_r(b7), do: {:non_reserved, :wrapper}
  
  def tag([[[[[[], b1], b2], b3], b4], b5]) when is_w(b1) and is_r(b2) and is_i(b3) and is_t(b4) and is_e(b5), do: {:non_reserved, :write}
  
  def tag([[[[[], b1], b2], b3], b4]) when is_z(b1) and is_o(b2) and is_n(b3) and is_e(b4), do: {:non_reserved, :zone}
  
  
  def tag([[[[], ?^], ?-], ?=]), do: {:operator, :"^-="}
  
  def tag([[[[], ?<], ?=], ?>]), do: {:operator, :"<=>"}
  
  def tag([[[[], ?-], ?>], ?>]), do: {:operator, :"->>"}
  
  def tag([[[[], ?|], ?|], ?/]), do: {:operator, :"||/"}
  
  def tag([[[[], ?!], ?~], ?*]), do: {:operator, :"!~*"}
  
  def tag([[[[], ?<], ?<], ?|]), do: {:operator, :"<<|"}
  
  def tag([[[[], ?|], ?>], ?>]), do: {:operator, :"|>>"}
  
  def tag([[[[], ?&], ?<], ?|]), do: {:operator, :"&<|"}
  
  def tag([[[[], ?|], ?&], ?>]), do: {:operator, :"|&>"}
  
  def tag([[[[], ??], ?-], ?|]), do: {:operator, :"?-|"}
  
  def tag([[[[], ??], ?|], ?|]), do: {:operator, :"?||"}
  
  def tag([[[[], ?<], ?<], ?=]), do: {:operator, :"<<="}
  
  def tag([[[[], ?>], ?>], ?=]), do: {:operator, :">>="}
  
  def tag([[[[], ?#], ?>], ?>]), do: {:operator, :"#>>"}
  
  def tag([[[[], ?-], ?|], ?-]), do: {:operator, :"-|-"}
  
  def tag([[[], ?&], ?&]), do: {:operator, :&&}
  
  def tag([[[], ?|], ?|]), do: {:operator, :||}
  
  def tag([[[], ?&], ?=]), do: {:operator, :"&="}
  
  def tag([[[], ?^], ?=]), do: {:operator, :"^="}
  
  def tag([[[], ?|], ?=]), do: {:operator, :"|="}
  
  def tag([[[[], ?|], ?*], ?=]), do: {:operator, :"|*="}
  
  def tag([[[], ?>], ?>]), do: {:operator, :">>"}
  
  def tag([[[], ?<], ?<]), do: {:operator, :"<<"}
  
  def tag([[[], ?-], ?>]), do: {:operator, :->}
  
  def tag([[[], ?:], ?=]), do: {:operator, :":="}
  
  def tag([[[], ?+], ?=]), do: {:operator, :"+="}
  
  def tag([[[], ?-], ?=]), do: {:operator, :"-="}
  
  def tag([[[], ?*], ?=]), do: {:operator, :"*="}
  
  def tag([[[], ?/], ?=]), do: {:operator, :"/="}
  
  def tag([[[], ?%], ?=]), do: {:operator, :"%="}
  
  def tag([[[], ?!], ?>]), do: {:operator, :"!>"}
  
  def tag([[[], ?!], ?<]), do: {:operator, :"!<"}
  
  def tag([[[], ?@], ?>]), do: {:operator, :"@>"}
  
  def tag([[[], ?<], ?@]), do: {:operator, :"<@"}
  
  def tag([[[], ?|], ?/]), do: {:operator, :"|/"}
  
  def tag([[[], ?^], ?@]), do: {:operator, :"^@"}
  
  def tag([[[], ?~], ?*]), do: {:operator, :"~*"}
  
  def tag([[[], ?!], ?~]), do: {:operator, :"!~"}
  
  def tag([[[], ?#], ?#]), do: {:operator, :"##"}
  
  def tag([[[], ?&], ?<]), do: {:operator, :"&<"}
  
  def tag([[[], ?&], ?>]), do: {:operator, :"&>"}
  
  def tag([[[], ?<], ?^]), do: {:operator, :"<^"}
  
  def tag([[[], ?>], ?^]), do: {:operator, :">^"}
  
  def tag([[[], ??], ?#]), do: {:operator, :"?#"}
  
  def tag([[[], ??], ?-]), do: {:operator, :"?-"}
  
  def tag([[[], ??], ?|]), do: {:operator, :"?|"}
  
  def tag([[[], ?~], ?=]), do: {:operator, :"~="}
  
  def tag([[[], ?@], ?@]), do: {:operator, :"@@"}
  
  def tag([[[], ?!], ?!]), do: {:operator, :"!!"}
  
  def tag([[[], ?#], ?>]), do: {:operator, :"#>"}
  
  def tag([[[], ??], ?&]), do: {:operator, :"?&"}
  
  def tag([[[], ?#], ?-]), do: {:operator, :"#-"}
  
  def tag([[[], ?@], ??]), do: {:operator, :"@?"}
  
  def tag([[[], ?:], ?:]), do: {:operator, :"::"}
  
  def tag([[[], ?<], ?>]), do: {:operator, :<>}
  
  def tag([[[], ?>], ?=]), do: {:operator, :>=}
  
  def tag([[[], ?<], ?=]), do: {:operator, :<=}
  
  def tag([[[], ?!], ?=]), do: {:operator, :!=}
  
  def tag([[], ?+]), do: {:operator, :+}
  
  def tag([[], ?-]), do: {:operator, :-}
  
  def tag([[], ?!]), do: {:operator, :!}
  
  def tag([[], ?&]), do: {:operator, :&}
  
  def tag([[], ?^]), do: {:operator, :^}
  
  def tag([[], ?|]), do: {:operator, :|}
  
  def tag([[], ?~]), do: {:operator, :"~"}
  
  def tag([[], ?%]), do: {:operator, :%}
  
  def tag([[], ?@]), do: {:operator, :@}
  
  def tag([[], ?#]), do: {:operator, :"#"}
  
  def tag([[], ?*]), do: {:operator, :*}
  
  def tag([[], ?/]), do: {:operator, :/}
  
  def tag([[], ?=]), do: {:operator, :=}
  
  def tag([[], ?>]), do: {:operator, :>}
  
  def tag([[], ?<]), do: {:operator, :<}
  
  def tag(_), do: nil
end
