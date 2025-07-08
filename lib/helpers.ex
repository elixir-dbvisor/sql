# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.Helpers do
  @moduledoc false

  defguard is_newline(b) when b in [10, 11, 12, 13, 133, 8232, 8233]
  defguard is_space(b) when b in ~c" "
  defguard is_whitespace(b) when b in [9, 13, 160, 160, 5760, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288, 6158, 8203, 8204, 8205, 8288, 65279]
  defguard is_literal(b) when b in ~c{"'`}
  defguard is_expr(b) when b in [:paren, :bracket, :brace]
  defguard is_nested_start(b) when b in ~c"([{"
  defguard is_nested_end(b) when b in ~c")]}"
  defguard is_special_character(b) when b in ~c" \"%&'()*+,-./:;<=>?[]^_|{}$'*@,$!>[(<-%.+?])/~#*/"
  defguard is_digit(b) when b in ~c"0123456789"
  defguard is_comment(b) when b in ["--", "/*"]
  defguard is_sign(b) when b in ~c"-+"
  defguard is_dot(b) when b == ?.
  defguard is_delimiter(b) when b in ~c";,"
  defguard is_operator(node) when elem(node, 0) in ~w"^-= <=> ->> ||/ !~* <<| |>> &<| |&> ?-| ?|| <<= >>= #>> -|- && || &= ^= |= |*= >> << -> := += -= *= /= %= !> !< @> <@ |/ ^@ ~* !~ ## &< &> <^ >^ ?# ?- ?| ~= @@ !! #> ?& #- @? :: <> >= <= != + - ! & ^ | ~ % @ # * / = > <"a
  
  defguard is_a(b) when b in ~c"aA"
  
  defguard is_b(b) when b in ~c"bB"
  
  defguard is_c(b) when b in ~c"cC"
  
  defguard is_d(b) when b in ~c"dD"
  
  defguard is_e(b) when b in ~c"eE"
  
  defguard is_f(b) when b in ~c"fF"
  
  defguard is_g(b) when b in ~c"gG"
  
  defguard is_h(b) when b in ~c"hH"
  
  defguard is_i(b) when b in ~c"iI"
  
  defguard is_j(b) when b in ~c"jJ"
  
  defguard is_k(b) when b in ~c"kK"
  
  defguard is_l(b) when b in ~c"lL"
  
  defguard is_m(b) when b in ~c"mM"
  
  defguard is_n(b) when b in ~c"nN"
  
  defguard is_o(b) when b in ~c"oO"
  
  defguard is_p(b) when b in ~c"pP"
  
  defguard is_q(b) when b in ~c"qQ"
  
  defguard is_r(b) when b in ~c"rR"
  
  defguard is_s(b) when b in ~c"sS"
  
  defguard is_t(b) when b in ~c"tT"
  
  defguard is_u(b) when b in ~c"uU"
  
  defguard is_v(b) when b in ~c"vV"
  
  defguard is_w(b) when b in ~c"wW"
  
  defguard is_x(b) when b in ~c"xX"
  
  defguard is_y(b) when b in ~c"yY"
  
  defguard is_z(b) when b in ~c"zZ"
  
  
  defguard is_kw_abs(node) when elem(hd(elem(node, 1)), 1) == :abs
  
  defguard is_kw_absent(node) when elem(hd(elem(node, 1)), 1) == :absent
  
  defguard is_kw_acos(node) when elem(hd(elem(node, 1)), 1) == :acos
  
  defguard is_kw_all(node) when elem(hd(elem(node, 1)), 1) == :all
  
  defguard is_kw_allocate(node) when elem(hd(elem(node, 1)), 1) == :allocate
  
  defguard is_kw_alter(node) when elem(hd(elem(node, 1)), 1) == :alter
  
  defguard is_kw_and(node) when elem(hd(elem(node, 1)), 1) == :and
  
  defguard is_kw_any(node) when elem(hd(elem(node, 1)), 1) == :any
  
  defguard is_kw_any_value(node) when elem(hd(elem(node, 1)), 1) == :any_value
  
  defguard is_kw_are(node) when elem(hd(elem(node, 1)), 1) == :are
  
  defguard is_kw_array(node) when elem(hd(elem(node, 1)), 1) == :array
  
  defguard is_kw_array_agg(node) when elem(hd(elem(node, 1)), 1) == :array_agg
  
  defguard is_kw_array_max_cardinality(node) when elem(hd(elem(node, 1)), 1) == :array_max_cardinality
  
  defguard is_kw_as(node) when elem(hd(elem(node, 1)), 1) == :as
  
  defguard is_kw_asensitive(node) when elem(hd(elem(node, 1)), 1) == :asensitive
  
  defguard is_kw_asin(node) when elem(hd(elem(node, 1)), 1) == :asin
  
  defguard is_kw_asymmetric(node) when elem(hd(elem(node, 1)), 1) == :asymmetric
  
  defguard is_kw_at(node) when elem(hd(elem(node, 1)), 1) == :at
  
  defguard is_kw_atan(node) when elem(hd(elem(node, 1)), 1) == :atan
  
  defguard is_kw_atomic(node) when elem(hd(elem(node, 1)), 1) == :atomic
  
  defguard is_kw_authorization(node) when elem(hd(elem(node, 1)), 1) == :authorization
  
  defguard is_kw_avg(node) when elem(hd(elem(node, 1)), 1) == :avg
  
  defguard is_kw_begin(node) when elem(hd(elem(node, 1)), 1) == :begin
  
  defguard is_kw_begin_frame(node) when elem(hd(elem(node, 1)), 1) == :begin_frame
  
  defguard is_kw_begin_partition(node) when elem(hd(elem(node, 1)), 1) == :begin_partition
  
  defguard is_kw_between(node) when elem(hd(elem(node, 1)), 1) == :between
  
  defguard is_kw_bigint(node) when elem(hd(elem(node, 1)), 1) == :bigint
  
  defguard is_kw_binary(node) when elem(hd(elem(node, 1)), 1) == :binary
  
  defguard is_kw_blob(node) when elem(hd(elem(node, 1)), 1) == :blob
  
  defguard is_kw_boolean(node) when elem(hd(elem(node, 1)), 1) == :boolean
  
  defguard is_kw_both(node) when elem(hd(elem(node, 1)), 1) == :both
  
  defguard is_kw_btrim(node) when elem(hd(elem(node, 1)), 1) == :btrim
  
  defguard is_kw_by(node) when elem(hd(elem(node, 1)), 1) == :by
  
  defguard is_kw_call(node) when elem(hd(elem(node, 1)), 1) == :call
  
  defguard is_kw_called(node) when elem(hd(elem(node, 1)), 1) == :called
  
  defguard is_kw_cardinality(node) when elem(hd(elem(node, 1)), 1) == :cardinality
  
  defguard is_kw_cascaded(node) when elem(hd(elem(node, 1)), 1) == :cascaded
  
  defguard is_kw_case(node) when elem(hd(elem(node, 1)), 1) == :case
  
  defguard is_kw_cast(node) when elem(hd(elem(node, 1)), 1) == :cast
  
  defguard is_kw_ceil(node) when elem(hd(elem(node, 1)), 1) == :ceil
  
  defguard is_kw_ceiling(node) when elem(hd(elem(node, 1)), 1) == :ceiling
  
  defguard is_kw_char(node) when elem(hd(elem(node, 1)), 1) == :char
  
  defguard is_kw_char_length(node) when elem(hd(elem(node, 1)), 1) == :char_length
  
  defguard is_kw_character(node) when elem(hd(elem(node, 1)), 1) == :character
  
  defguard is_kw_character_length(node) when elem(hd(elem(node, 1)), 1) == :character_length
  
  defguard is_kw_check(node) when elem(hd(elem(node, 1)), 1) == :check
  
  defguard is_kw_classifier(node) when elem(hd(elem(node, 1)), 1) == :classifier
  
  defguard is_kw_clob(node) when elem(hd(elem(node, 1)), 1) == :clob
  
  defguard is_kw_close(node) when elem(hd(elem(node, 1)), 1) == :close
  
  defguard is_kw_coalesce(node) when elem(hd(elem(node, 1)), 1) == :coalesce
  
  defguard is_kw_collate(node) when elem(hd(elem(node, 1)), 1) == :collate
  
  defguard is_kw_collect(node) when elem(hd(elem(node, 1)), 1) == :collect
  
  defguard is_kw_column(node) when elem(hd(elem(node, 1)), 1) == :column
  
  defguard is_kw_commit(node) when elem(hd(elem(node, 1)), 1) == :commit
  
  defguard is_kw_condition(node) when elem(hd(elem(node, 1)), 1) == :condition
  
  defguard is_kw_connect(node) when elem(hd(elem(node, 1)), 1) == :connect
  
  defguard is_kw_constraint(node) when elem(hd(elem(node, 1)), 1) == :constraint
  
  defguard is_kw_contains(node) when elem(hd(elem(node, 1)), 1) == :contains
  
  defguard is_kw_convert(node) when elem(hd(elem(node, 1)), 1) == :convert
  
  defguard is_kw_copy(node) when elem(hd(elem(node, 1)), 1) == :copy
  
  defguard is_kw_corr(node) when elem(hd(elem(node, 1)), 1) == :corr
  
  defguard is_kw_corresponding(node) when elem(hd(elem(node, 1)), 1) == :corresponding
  
  defguard is_kw_cos(node) when elem(hd(elem(node, 1)), 1) == :cos
  
  defguard is_kw_cosh(node) when elem(hd(elem(node, 1)), 1) == :cosh
  
  defguard is_kw_count(node) when elem(hd(elem(node, 1)), 1) == :count
  
  defguard is_kw_covar_pop(node) when elem(hd(elem(node, 1)), 1) == :covar_pop
  
  defguard is_kw_covar_samp(node) when elem(hd(elem(node, 1)), 1) == :covar_samp
  
  defguard is_kw_create(node) when elem(hd(elem(node, 1)), 1) == :create
  
  defguard is_kw_cross(node) when elem(hd(elem(node, 1)), 1) == :cross
  
  defguard is_kw_cube(node) when elem(hd(elem(node, 1)), 1) == :cube
  
  defguard is_kw_cume_dist(node) when elem(hd(elem(node, 1)), 1) == :cume_dist
  
  defguard is_kw_current(node) when elem(hd(elem(node, 1)), 1) == :current
  
  defguard is_kw_current_catalog(node) when elem(hd(elem(node, 1)), 1) == :current_catalog
  
  defguard is_kw_current_date(node) when elem(hd(elem(node, 1)), 1) == :current_date
  
  defguard is_kw_current_default_transform_group(node) when elem(hd(elem(node, 1)), 1) == :current_default_transform_group
  
  defguard is_kw_current_path(node) when elem(hd(elem(node, 1)), 1) == :current_path
  
  defguard is_kw_current_role(node) when elem(hd(elem(node, 1)), 1) == :current_role
  
  defguard is_kw_current_row(node) when elem(hd(elem(node, 1)), 1) == :current_row
  
  defguard is_kw_current_schema(node) when elem(hd(elem(node, 1)), 1) == :current_schema
  
  defguard is_kw_current_time(node) when elem(hd(elem(node, 1)), 1) == :current_time
  
  defguard is_kw_current_timestamp(node) when elem(hd(elem(node, 1)), 1) == :current_timestamp
  
  defguard is_kw_current_transform_group_for_type(node) when elem(hd(elem(node, 1)), 1) == :current_transform_group_for_type
  
  defguard is_kw_current_user(node) when elem(hd(elem(node, 1)), 1) == :current_user
  
  defguard is_kw_cursor(node) when elem(hd(elem(node, 1)), 1) == :cursor
  
  defguard is_kw_cycle(node) when elem(hd(elem(node, 1)), 1) == :cycle
  
  defguard is_kw_date(node) when elem(hd(elem(node, 1)), 1) == :date
  
  defguard is_kw_day(node) when elem(hd(elem(node, 1)), 1) == :day
  
  defguard is_kw_deallocate(node) when elem(hd(elem(node, 1)), 1) == :deallocate
  
  defguard is_kw_dec(node) when elem(hd(elem(node, 1)), 1) == :dec
  
  defguard is_kw_decfloat(node) when elem(hd(elem(node, 1)), 1) == :decfloat
  
  defguard is_kw_decimal(node) when elem(hd(elem(node, 1)), 1) == :decimal
  
  defguard is_kw_declare(node) when elem(hd(elem(node, 1)), 1) == :declare
  
  defguard is_kw_default(node) when elem(hd(elem(node, 1)), 1) == :default
  
  defguard is_kw_define(node) when elem(hd(elem(node, 1)), 1) == :define
  
  defguard is_kw_delete(node) when elem(hd(elem(node, 1)), 1) == :delete
  
  defguard is_kw_dense_rank(node) when elem(hd(elem(node, 1)), 1) == :dense_rank
  
  defguard is_kw_deref(node) when elem(hd(elem(node, 1)), 1) == :deref
  
  defguard is_kw_describe(node) when elem(hd(elem(node, 1)), 1) == :describe
  
  defguard is_kw_deterministic(node) when elem(hd(elem(node, 1)), 1) == :deterministic
  
  defguard is_kw_disconnect(node) when elem(hd(elem(node, 1)), 1) == :disconnect
  
  defguard is_kw_distinct(node) when elem(hd(elem(node, 1)), 1) == :distinct
  
  defguard is_kw_double(node) when elem(hd(elem(node, 1)), 1) == :double
  
  defguard is_kw_drop(node) when elem(hd(elem(node, 1)), 1) == :drop
  
  defguard is_kw_dynamic(node) when elem(hd(elem(node, 1)), 1) == :dynamic
  
  defguard is_kw_each(node) when elem(hd(elem(node, 1)), 1) == :each
  
  defguard is_kw_element(node) when elem(hd(elem(node, 1)), 1) == :element
  
  defguard is_kw_else(node) when elem(hd(elem(node, 1)), 1) == :else
  
  defguard is_kw_empty(node) when elem(hd(elem(node, 1)), 1) == :empty
  
  defguard is_kw_end(node) when elem(hd(elem(node, 1)), 1) == :end
  
  defguard is_kw_end_frame(node) when elem(hd(elem(node, 1)), 1) == :end_frame
  
  defguard is_kw_end_partition(node) when elem(hd(elem(node, 1)), 1) == :end_partition
  
  defguard is_kw_end_exec(node) when elem(hd(elem(node, 1)), 1) == :"end-exec"
  
  defguard is_kw_equals(node) when elem(hd(elem(node, 1)), 1) == :equals
  
  defguard is_kw_escape(node) when elem(hd(elem(node, 1)), 1) == :escape
  
  defguard is_kw_every(node) when elem(hd(elem(node, 1)), 1) == :every
  
  defguard is_kw_except(node) when elem(hd(elem(node, 1)), 1) == :except
  
  defguard is_kw_exec(node) when elem(hd(elem(node, 1)), 1) == :exec
  
  defguard is_kw_execute(node) when elem(hd(elem(node, 1)), 1) == :execute
  
  defguard is_kw_exists(node) when elem(hd(elem(node, 1)), 1) == :exists
  
  defguard is_kw_exp(node) when elem(hd(elem(node, 1)), 1) == :exp
  
  defguard is_kw_external(node) when elem(hd(elem(node, 1)), 1) == :external
  
  defguard is_kw_extract(node) when elem(hd(elem(node, 1)), 1) == :extract
  
  defguard is_kw_false(node) when elem(hd(elem(node, 1)), 1) == false
  
  defguard is_kw_fetch(node) when elem(hd(elem(node, 1)), 1) == :fetch
  
  defguard is_kw_filter(node) when elem(hd(elem(node, 1)), 1) == :filter
  
  defguard is_kw_first_value(node) when elem(hd(elem(node, 1)), 1) == :first_value
  
  defguard is_kw_float(node) when elem(hd(elem(node, 1)), 1) == :float
  
  defguard is_kw_floor(node) when elem(hd(elem(node, 1)), 1) == :floor
  
  defguard is_kw_for(node) when elem(hd(elem(node, 1)), 1) == :for
  
  defguard is_kw_foreign(node) when elem(hd(elem(node, 1)), 1) == :foreign
  
  defguard is_kw_frame_row(node) when elem(hd(elem(node, 1)), 1) == :frame_row
  
  defguard is_kw_free(node) when elem(hd(elem(node, 1)), 1) == :free
  
  defguard is_kw_from(node) when elem(hd(elem(node, 1)), 1) == :from
  
  defguard is_kw_full(node) when elem(hd(elem(node, 1)), 1) == :full
  
  defguard is_kw_function(node) when elem(hd(elem(node, 1)), 1) == :function
  
  defguard is_kw_fusion(node) when elem(hd(elem(node, 1)), 1) == :fusion
  
  defguard is_kw_get(node) when elem(hd(elem(node, 1)), 1) == :get
  
  defguard is_kw_global(node) when elem(hd(elem(node, 1)), 1) == :global
  
  defguard is_kw_grant(node) when elem(hd(elem(node, 1)), 1) == :grant
  
  defguard is_kw_greatest(node) when elem(hd(elem(node, 1)), 1) == :greatest
  
  defguard is_kw_group(node) when elem(hd(elem(node, 1)), 1) == :group
  
  defguard is_kw_grouping(node) when elem(hd(elem(node, 1)), 1) == :grouping
  
  defguard is_kw_groups(node) when elem(hd(elem(node, 1)), 1) == :groups
  
  defguard is_kw_having(node) when elem(hd(elem(node, 1)), 1) == :having
  
  defguard is_kw_hold(node) when elem(hd(elem(node, 1)), 1) == :hold
  
  defguard is_kw_hour(node) when elem(hd(elem(node, 1)), 1) == :hour
  
  defguard is_kw_identity(node) when elem(hd(elem(node, 1)), 1) == :identity
  
  defguard is_kw_in(node) when elem(hd(elem(node, 1)), 1) == :in
  
  defguard is_kw_indicator(node) when elem(hd(elem(node, 1)), 1) == :indicator
  
  defguard is_kw_initial(node) when elem(hd(elem(node, 1)), 1) == :initial
  
  defguard is_kw_inner(node) when elem(hd(elem(node, 1)), 1) == :inner
  
  defguard is_kw_inout(node) when elem(hd(elem(node, 1)), 1) == :inout
  
  defguard is_kw_insensitive(node) when elem(hd(elem(node, 1)), 1) == :insensitive
  
  defguard is_kw_insert(node) when elem(hd(elem(node, 1)), 1) == :insert
  
  defguard is_kw_int(node) when elem(hd(elem(node, 1)), 1) == :int
  
  defguard is_kw_integer(node) when elem(hd(elem(node, 1)), 1) == :integer
  
  defguard is_kw_intersect(node) when elem(hd(elem(node, 1)), 1) == :intersect
  
  defguard is_kw_intersection(node) when elem(hd(elem(node, 1)), 1) == :intersection
  
  defguard is_kw_interval(node) when elem(hd(elem(node, 1)), 1) == :interval
  
  defguard is_kw_into(node) when elem(hd(elem(node, 1)), 1) == :into
  
  defguard is_kw_is(node) when elem(hd(elem(node, 1)), 1) == :is
  
  defguard is_kw_join(node) when elem(hd(elem(node, 1)), 1) == :join
  
  defguard is_kw_json(node) when elem(hd(elem(node, 1)), 1) == :json
  
  defguard is_kw_json_array(node) when elem(hd(elem(node, 1)), 1) == :json_array
  
  defguard is_kw_json_arrayagg(node) when elem(hd(elem(node, 1)), 1) == :json_arrayagg
  
  defguard is_kw_json_exists(node) when elem(hd(elem(node, 1)), 1) == :json_exists
  
  defguard is_kw_json_object(node) when elem(hd(elem(node, 1)), 1) == :json_object
  
  defguard is_kw_json_objectagg(node) when elem(hd(elem(node, 1)), 1) == :json_objectagg
  
  defguard is_kw_json_query(node) when elem(hd(elem(node, 1)), 1) == :json_query
  
  defguard is_kw_json_scalar(node) when elem(hd(elem(node, 1)), 1) == :json_scalar
  
  defguard is_kw_json_serialize(node) when elem(hd(elem(node, 1)), 1) == :json_serialize
  
  defguard is_kw_json_table(node) when elem(hd(elem(node, 1)), 1) == :json_table
  
  defguard is_kw_json_table_primitive(node) when elem(hd(elem(node, 1)), 1) == :json_table_primitive
  
  defguard is_kw_json_value(node) when elem(hd(elem(node, 1)), 1) == :json_value
  
  defguard is_kw_lag(node) when elem(hd(elem(node, 1)), 1) == :lag
  
  defguard is_kw_language(node) when elem(hd(elem(node, 1)), 1) == :language
  
  defguard is_kw_large(node) when elem(hd(elem(node, 1)), 1) == :large
  
  defguard is_kw_last_value(node) when elem(hd(elem(node, 1)), 1) == :last_value
  
  defguard is_kw_lateral(node) when elem(hd(elem(node, 1)), 1) == :lateral
  
  defguard is_kw_lead(node) when elem(hd(elem(node, 1)), 1) == :lead
  
  defguard is_kw_leading(node) when elem(hd(elem(node, 1)), 1) == :leading
  
  defguard is_kw_least(node) when elem(hd(elem(node, 1)), 1) == :least
  
  defguard is_kw_left(node) when elem(hd(elem(node, 1)), 1) == :left
  
  defguard is_kw_like(node) when elem(hd(elem(node, 1)), 1) == :like
  
  defguard is_kw_like_regex(node) when elem(hd(elem(node, 1)), 1) == :like_regex
  
  defguard is_kw_listagg(node) when elem(hd(elem(node, 1)), 1) == :listagg
  
  defguard is_kw_ln(node) when elem(hd(elem(node, 1)), 1) == :ln
  
  defguard is_kw_local(node) when elem(hd(elem(node, 1)), 1) == :local
  
  defguard is_kw_localtime(node) when elem(hd(elem(node, 1)), 1) == :localtime
  
  defguard is_kw_localtimestamp(node) when elem(hd(elem(node, 1)), 1) == :localtimestamp
  
  defguard is_kw_log(node) when elem(hd(elem(node, 1)), 1) == :log
  
  defguard is_kw_log10(node) when elem(hd(elem(node, 1)), 1) == :log10
  
  defguard is_kw_lower(node) when elem(hd(elem(node, 1)), 1) == :lower
  
  defguard is_kw_lpad(node) when elem(hd(elem(node, 1)), 1) == :lpad
  
  defguard is_kw_ltrim(node) when elem(hd(elem(node, 1)), 1) == :ltrim
  
  defguard is_kw_match(node) when elem(hd(elem(node, 1)), 1) == :match
  
  defguard is_kw_match_number(node) when elem(hd(elem(node, 1)), 1) == :match_number
  
  defguard is_kw_match_recognize(node) when elem(hd(elem(node, 1)), 1) == :match_recognize
  
  defguard is_kw_matches(node) when elem(hd(elem(node, 1)), 1) == :matches
  
  defguard is_kw_max(node) when elem(hd(elem(node, 1)), 1) == :max
  
  defguard is_kw_member(node) when elem(hd(elem(node, 1)), 1) == :member
  
  defguard is_kw_merge(node) when elem(hd(elem(node, 1)), 1) == :merge
  
  defguard is_kw_method(node) when elem(hd(elem(node, 1)), 1) == :method
  
  defguard is_kw_min(node) when elem(hd(elem(node, 1)), 1) == :min
  
  defguard is_kw_minute(node) when elem(hd(elem(node, 1)), 1) == :minute
  
  defguard is_kw_mod(node) when elem(hd(elem(node, 1)), 1) == :mod
  
  defguard is_kw_modifies(node) when elem(hd(elem(node, 1)), 1) == :modifies
  
  defguard is_kw_module(node) when elem(hd(elem(node, 1)), 1) == :module
  
  defguard is_kw_month(node) when elem(hd(elem(node, 1)), 1) == :month
  
  defguard is_kw_multiset(node) when elem(hd(elem(node, 1)), 1) == :multiset
  
  defguard is_kw_national(node) when elem(hd(elem(node, 1)), 1) == :national
  
  defguard is_kw_natural(node) when elem(hd(elem(node, 1)), 1) == :natural
  
  defguard is_kw_nchar(node) when elem(hd(elem(node, 1)), 1) == :nchar
  
  defguard is_kw_nclob(node) when elem(hd(elem(node, 1)), 1) == :nclob
  
  defguard is_kw_new(node) when elem(hd(elem(node, 1)), 1) == :new
  
  defguard is_kw_no(node) when elem(hd(elem(node, 1)), 1) == :no
  
  defguard is_kw_none(node) when elem(hd(elem(node, 1)), 1) == :none
  
  defguard is_kw_normalize(node) when elem(hd(elem(node, 1)), 1) == :normalize
  
  defguard is_kw_not(node) when elem(hd(elem(node, 1)), 1) == :not
  
  defguard is_kw_nth_value(node) when elem(hd(elem(node, 1)), 1) == :nth_value
  
  defguard is_kw_ntile(node) when elem(hd(elem(node, 1)), 1) == :ntile
  
  defguard is_kw_null(node) when elem(hd(elem(node, 1)), 1) == :null
  
  defguard is_kw_nullif(node) when elem(hd(elem(node, 1)), 1) == :nullif
  
  defguard is_kw_numeric(node) when elem(hd(elem(node, 1)), 1) == :numeric
  
  defguard is_kw_occurrences_regex(node) when elem(hd(elem(node, 1)), 1) == :occurrences_regex
  
  defguard is_kw_octet_length(node) when elem(hd(elem(node, 1)), 1) == :octet_length
  
  defguard is_kw_of(node) when elem(hd(elem(node, 1)), 1) == :of
  
  defguard is_kw_offset(node) when elem(hd(elem(node, 1)), 1) == :offset
  
  defguard is_kw_old(node) when elem(hd(elem(node, 1)), 1) == :old
  
  defguard is_kw_omit(node) when elem(hd(elem(node, 1)), 1) == :omit
  
  defguard is_kw_on(node) when elem(hd(elem(node, 1)), 1) == :on
  
  defguard is_kw_one(node) when elem(hd(elem(node, 1)), 1) == :one
  
  defguard is_kw_only(node) when elem(hd(elem(node, 1)), 1) == :only
  
  defguard is_kw_open(node) when elem(hd(elem(node, 1)), 1) == :open
  
  defguard is_kw_or(node) when elem(hd(elem(node, 1)), 1) == :or
  
  defguard is_kw_order(node) when elem(hd(elem(node, 1)), 1) == :order
  
  defguard is_kw_out(node) when elem(hd(elem(node, 1)), 1) == :out
  
  defguard is_kw_outer(node) when elem(hd(elem(node, 1)), 1) == :outer
  
  defguard is_kw_over(node) when elem(hd(elem(node, 1)), 1) == :over
  
  defguard is_kw_overlaps(node) when elem(hd(elem(node, 1)), 1) == :overlaps
  
  defguard is_kw_overlay(node) when elem(hd(elem(node, 1)), 1) == :overlay
  
  defguard is_kw_parameter(node) when elem(hd(elem(node, 1)), 1) == :parameter
  
  defguard is_kw_partition(node) when elem(hd(elem(node, 1)), 1) == :partition
  
  defguard is_kw_pattern(node) when elem(hd(elem(node, 1)), 1) == :pattern
  
  defguard is_kw_per(node) when elem(hd(elem(node, 1)), 1) == :per
  
  defguard is_kw_percent(node) when elem(hd(elem(node, 1)), 1) == :percent
  
  defguard is_kw_percent_rank(node) when elem(hd(elem(node, 1)), 1) == :percent_rank
  
  defguard is_kw_percentile_cont(node) when elem(hd(elem(node, 1)), 1) == :percentile_cont
  
  defguard is_kw_percentile_disc(node) when elem(hd(elem(node, 1)), 1) == :percentile_disc
  
  defguard is_kw_period(node) when elem(hd(elem(node, 1)), 1) == :period
  
  defguard is_kw_portion(node) when elem(hd(elem(node, 1)), 1) == :portion
  
  defguard is_kw_position(node) when elem(hd(elem(node, 1)), 1) == :position
  
  defguard is_kw_position_regex(node) when elem(hd(elem(node, 1)), 1) == :position_regex
  
  defguard is_kw_power(node) when elem(hd(elem(node, 1)), 1) == :power
  
  defguard is_kw_precedes(node) when elem(hd(elem(node, 1)), 1) == :precedes
  
  defguard is_kw_precision(node) when elem(hd(elem(node, 1)), 1) == :precision
  
  defguard is_kw_prepare(node) when elem(hd(elem(node, 1)), 1) == :prepare
  
  defguard is_kw_primary(node) when elem(hd(elem(node, 1)), 1) == :primary
  
  defguard is_kw_procedure(node) when elem(hd(elem(node, 1)), 1) == :procedure
  
  defguard is_kw_ptf(node) when elem(hd(elem(node, 1)), 1) == :ptf
  
  defguard is_kw_range(node) when elem(hd(elem(node, 1)), 1) == :range
  
  defguard is_kw_rank(node) when elem(hd(elem(node, 1)), 1) == :rank
  
  defguard is_kw_reads(node) when elem(hd(elem(node, 1)), 1) == :reads
  
  defguard is_kw_real(node) when elem(hd(elem(node, 1)), 1) == :real
  
  defguard is_kw_recursive(node) when elem(hd(elem(node, 1)), 1) == :recursive
  
  defguard is_kw_ref(node) when elem(hd(elem(node, 1)), 1) == :ref
  
  defguard is_kw_references(node) when elem(hd(elem(node, 1)), 1) == :references
  
  defguard is_kw_referencing(node) when elem(hd(elem(node, 1)), 1) == :referencing
  
  defguard is_kw_regr_avgx(node) when elem(hd(elem(node, 1)), 1) == :regr_avgx
  
  defguard is_kw_regr_avgy(node) when elem(hd(elem(node, 1)), 1) == :regr_avgy
  
  defguard is_kw_regr_count(node) when elem(hd(elem(node, 1)), 1) == :regr_count
  
  defguard is_kw_regr_intercept(node) when elem(hd(elem(node, 1)), 1) == :regr_intercept
  
  defguard is_kw_regr_r2(node) when elem(hd(elem(node, 1)), 1) == :regr_r2
  
  defguard is_kw_regr_slope(node) when elem(hd(elem(node, 1)), 1) == :regr_slope
  
  defguard is_kw_regr_sxx(node) when elem(hd(elem(node, 1)), 1) == :regr_sxx
  
  defguard is_kw_regr_sxy(node) when elem(hd(elem(node, 1)), 1) == :regr_sxy
  
  defguard is_kw_regr_syy(node) when elem(hd(elem(node, 1)), 1) == :regr_syy
  
  defguard is_kw_release(node) when elem(hd(elem(node, 1)), 1) == :release
  
  defguard is_kw_result(node) when elem(hd(elem(node, 1)), 1) == :result
  
  defguard is_kw_return(node) when elem(hd(elem(node, 1)), 1) == :return
  
  defguard is_kw_returns(node) when elem(hd(elem(node, 1)), 1) == :returns
  
  defguard is_kw_revoke(node) when elem(hd(elem(node, 1)), 1) == :revoke
  
  defguard is_kw_right(node) when elem(hd(elem(node, 1)), 1) == :right
  
  defguard is_kw_rollback(node) when elem(hd(elem(node, 1)), 1) == :rollback
  
  defguard is_kw_rollup(node) when elem(hd(elem(node, 1)), 1) == :rollup
  
  defguard is_kw_row(node) when elem(hd(elem(node, 1)), 1) == :row
  
  defguard is_kw_row_number(node) when elem(hd(elem(node, 1)), 1) == :row_number
  
  defguard is_kw_rows(node) when elem(hd(elem(node, 1)), 1) == :rows
  
  defguard is_kw_rpad(node) when elem(hd(elem(node, 1)), 1) == :rpad
  
  defguard is_kw_rtrim(node) when elem(hd(elem(node, 1)), 1) == :rtrim
  
  defguard is_kw_running(node) when elem(hd(elem(node, 1)), 1) == :running
  
  defguard is_kw_savepoint(node) when elem(hd(elem(node, 1)), 1) == :savepoint
  
  defguard is_kw_scope(node) when elem(hd(elem(node, 1)), 1) == :scope
  
  defguard is_kw_scroll(node) when elem(hd(elem(node, 1)), 1) == :scroll
  
  defguard is_kw_search(node) when elem(hd(elem(node, 1)), 1) == :search
  
  defguard is_kw_second(node) when elem(hd(elem(node, 1)), 1) == :second
  
  defguard is_kw_seek(node) when elem(hd(elem(node, 1)), 1) == :seek
  
  defguard is_kw_select(node) when elem(hd(elem(node, 1)), 1) == :select
  
  defguard is_kw_sensitive(node) when elem(hd(elem(node, 1)), 1) == :sensitive
  
  defguard is_kw_session_user(node) when elem(hd(elem(node, 1)), 1) == :session_user
  
  defguard is_kw_set(node) when elem(hd(elem(node, 1)), 1) == :set
  
  defguard is_kw_show(node) when elem(hd(elem(node, 1)), 1) == :show
  
  defguard is_kw_similar(node) when elem(hd(elem(node, 1)), 1) == :similar
  
  defguard is_kw_sin(node) when elem(hd(elem(node, 1)), 1) == :sin
  
  defguard is_kw_sinh(node) when elem(hd(elem(node, 1)), 1) == :sinh
  
  defguard is_kw_skip(node) when elem(hd(elem(node, 1)), 1) == :skip
  
  defguard is_kw_smallint(node) when elem(hd(elem(node, 1)), 1) == :smallint
  
  defguard is_kw_some(node) when elem(hd(elem(node, 1)), 1) == :some
  
  defguard is_kw_specific(node) when elem(hd(elem(node, 1)), 1) == :specific
  
  defguard is_kw_specifictype(node) when elem(hd(elem(node, 1)), 1) == :specifictype
  
  defguard is_kw_sql(node) when elem(hd(elem(node, 1)), 1) == :sql
  
  defguard is_kw_sqlexception(node) when elem(hd(elem(node, 1)), 1) == :sqlexception
  
  defguard is_kw_sqlstate(node) when elem(hd(elem(node, 1)), 1) == :sqlstate
  
  defguard is_kw_sqlwarning(node) when elem(hd(elem(node, 1)), 1) == :sqlwarning
  
  defguard is_kw_sqrt(node) when elem(hd(elem(node, 1)), 1) == :sqrt
  
  defguard is_kw_start(node) when elem(hd(elem(node, 1)), 1) == :start
  
  defguard is_kw_static(node) when elem(hd(elem(node, 1)), 1) == :static
  
  defguard is_kw_stddev_pop(node) when elem(hd(elem(node, 1)), 1) == :stddev_pop
  
  defguard is_kw_stddev_samp(node) when elem(hd(elem(node, 1)), 1) == :stddev_samp
  
  defguard is_kw_submultiset(node) when elem(hd(elem(node, 1)), 1) == :submultiset
  
  defguard is_kw_subset(node) when elem(hd(elem(node, 1)), 1) == :subset
  
  defguard is_kw_substring(node) when elem(hd(elem(node, 1)), 1) == :substring
  
  defguard is_kw_substring_regex(node) when elem(hd(elem(node, 1)), 1) == :substring_regex
  
  defguard is_kw_succeeds(node) when elem(hd(elem(node, 1)), 1) == :succeeds
  
  defguard is_kw_sum(node) when elem(hd(elem(node, 1)), 1) == :sum
  
  defguard is_kw_symmetric(node) when elem(hd(elem(node, 1)), 1) == :symmetric
  
  defguard is_kw_system(node) when elem(hd(elem(node, 1)), 1) == :system
  
  defguard is_kw_system_time(node) when elem(hd(elem(node, 1)), 1) == :system_time
  
  defguard is_kw_system_user(node) when elem(hd(elem(node, 1)), 1) == :system_user
  
  defguard is_kw_table(node) when elem(hd(elem(node, 1)), 1) == :table
  
  defguard is_kw_tablesample(node) when elem(hd(elem(node, 1)), 1) == :tablesample
  
  defguard is_kw_tan(node) when elem(hd(elem(node, 1)), 1) == :tan
  
  defguard is_kw_tanh(node) when elem(hd(elem(node, 1)), 1) == :tanh
  
  defguard is_kw_then(node) when elem(hd(elem(node, 1)), 1) == :then
  
  defguard is_kw_time(node) when elem(hd(elem(node, 1)), 1) == :time
  
  defguard is_kw_timestamp(node) when elem(hd(elem(node, 1)), 1) == :timestamp
  
  defguard is_kw_timezone_hour(node) when elem(hd(elem(node, 1)), 1) == :timezone_hour
  
  defguard is_kw_timezone_minute(node) when elem(hd(elem(node, 1)), 1) == :timezone_minute
  
  defguard is_kw_to(node) when elem(hd(elem(node, 1)), 1) == :to
  
  defguard is_kw_trailing(node) when elem(hd(elem(node, 1)), 1) == :trailing
  
  defguard is_kw_translate(node) when elem(hd(elem(node, 1)), 1) == :translate
  
  defguard is_kw_translate_regex(node) when elem(hd(elem(node, 1)), 1) == :translate_regex
  
  defguard is_kw_translation(node) when elem(hd(elem(node, 1)), 1) == :translation
  
  defguard is_kw_treat(node) when elem(hd(elem(node, 1)), 1) == :treat
  
  defguard is_kw_trigger(node) when elem(hd(elem(node, 1)), 1) == :trigger
  
  defguard is_kw_trim(node) when elem(hd(elem(node, 1)), 1) == :trim
  
  defguard is_kw_trim_array(node) when elem(hd(elem(node, 1)), 1) == :trim_array
  
  defguard is_kw_true(node) when elem(hd(elem(node, 1)), 1) == true
  
  defguard is_kw_truncate(node) when elem(hd(elem(node, 1)), 1) == :truncate
  
  defguard is_kw_uescape(node) when elem(hd(elem(node, 1)), 1) == :uescape
  
  defguard is_kw_union(node) when elem(hd(elem(node, 1)), 1) == :union
  
  defguard is_kw_unique(node) when elem(hd(elem(node, 1)), 1) == :unique
  
  defguard is_kw_unknown(node) when elem(hd(elem(node, 1)), 1) == :unknown
  
  defguard is_kw_unnest(node) when elem(hd(elem(node, 1)), 1) == :unnest
  
  defguard is_kw_update(node) when elem(hd(elem(node, 1)), 1) == :update
  
  defguard is_kw_upper(node) when elem(hd(elem(node, 1)), 1) == :upper
  
  defguard is_kw_user(node) when elem(hd(elem(node, 1)), 1) == :user
  
  defguard is_kw_using(node) when elem(hd(elem(node, 1)), 1) == :using
  
  defguard is_kw_value(node) when elem(hd(elem(node, 1)), 1) == :value
  
  defguard is_kw_values(node) when elem(hd(elem(node, 1)), 1) == :values
  
  defguard is_kw_value_of(node) when elem(hd(elem(node, 1)), 1) == :value_of
  
  defguard is_kw_var_pop(node) when elem(hd(elem(node, 1)), 1) == :var_pop
  
  defguard is_kw_var_samp(node) when elem(hd(elem(node, 1)), 1) == :var_samp
  
  defguard is_kw_varbinary(node) when elem(hd(elem(node, 1)), 1) == :varbinary
  
  defguard is_kw_varchar(node) when elem(hd(elem(node, 1)), 1) == :varchar
  
  defguard is_kw_varying(node) when elem(hd(elem(node, 1)), 1) == :varying
  
  defguard is_kw_versioning(node) when elem(hd(elem(node, 1)), 1) == :versioning
  
  defguard is_kw_when(node) when elem(hd(elem(node, 1)), 1) == :when
  
  defguard is_kw_whenever(node) when elem(hd(elem(node, 1)), 1) == :whenever
  
  defguard is_kw_where(node) when elem(hd(elem(node, 1)), 1) == :where
  
  defguard is_kw_width_bucket(node) when elem(hd(elem(node, 1)), 1) == :width_bucket
  
  defguard is_kw_window(node) when elem(hd(elem(node, 1)), 1) == :window
  
  defguard is_kw_with(node) when elem(hd(elem(node, 1)), 1) == :with
  
  defguard is_kw_within(node) when elem(hd(elem(node, 1)), 1) == :within
  
  defguard is_kw_without(node) when elem(hd(elem(node, 1)), 1) == :without
  
  defguard is_kw_year(node) when elem(hd(elem(node, 1)), 1) == :year
  
  defguard is_kw_limit(node) when elem(hd(elem(node, 1)), 1) == :limit
  
  defguard is_kw_ilike(node) when elem(hd(elem(node, 1)), 1) == :ilike
  
  defguard is_kw_backward(node) when elem(hd(elem(node, 1)), 1) == :backward
  
  defguard is_kw_forward(node) when elem(hd(elem(node, 1)), 1) == :forward
  
  defguard is_kw_isnull(node) when elem(hd(elem(node, 1)), 1) == :isnull
  
  defguard is_kw_notnull(node) when elem(hd(elem(node, 1)), 1) == :notnull
  
  defguard is_kw_datetime(node) when elem(hd(elem(node, 1)), 1) == :datetime
  
  defguard is_kw_flag(node) when elem(hd(elem(node, 1)), 1) == :flag
  
  defguard is_kw_keyvalue(node) when elem(hd(elem(node, 1)), 1) == :keyvalue
  
  defguard is_kw_last(node) when elem(hd(elem(node, 1)), 1) == :last
  
  defguard is_kw_lax(node) when elem(hd(elem(node, 1)), 1) == :lax
  
  defguard is_kw_number(node) when elem(hd(elem(node, 1)), 1) == :number
  
  defguard is_kw_size(node) when elem(hd(elem(node, 1)), 1) == :size
  
  defguard is_kw_starts(node) when elem(hd(elem(node, 1)), 1) == :starts
  
  defguard is_kw_strict(node) when elem(hd(elem(node, 1)), 1) == :strict
  
  defguard is_kw_string(node) when elem(hd(elem(node, 1)), 1) == :string
  
  defguard is_kw_time_tz(node) when elem(hd(elem(node, 1)), 1) == :time_tz
  
  defguard is_kw_timestamp_tz(node) when elem(hd(elem(node, 1)), 1) == :timestamp_tz
  
  defguard is_kw_type(node) when elem(hd(elem(node, 1)), 1) == :type
  
  defguard is_kw_a(node) when elem(hd(elem(node, 1)), 1) == :a
  
  defguard is_kw_absolute(node) when elem(hd(elem(node, 1)), 1) == :absolute
  
  defguard is_kw_action(node) when elem(hd(elem(node, 1)), 1) == :action
  
  defguard is_kw_ada(node) when elem(hd(elem(node, 1)), 1) == :ada
  
  defguard is_kw_add(node) when elem(hd(elem(node, 1)), 1) == :add
  
  defguard is_kw_admin(node) when elem(hd(elem(node, 1)), 1) == :admin
  
  defguard is_kw_after(node) when elem(hd(elem(node, 1)), 1) == :after
  
  defguard is_kw_always(node) when elem(hd(elem(node, 1)), 1) == :always
  
  defguard is_kw_asc(node) when elem(hd(elem(node, 1)), 1) == :asc
  
  defguard is_kw_assertion(node) when elem(hd(elem(node, 1)), 1) == :assertion
  
  defguard is_kw_assignment(node) when elem(hd(elem(node, 1)), 1) == :assignment
  
  defguard is_kw_attribute(node) when elem(hd(elem(node, 1)), 1) == :attribute
  
  defguard is_kw_attributes(node) when elem(hd(elem(node, 1)), 1) == :attributes
  
  defguard is_kw_before(node) when elem(hd(elem(node, 1)), 1) == :before
  
  defguard is_kw_bernoulli(node) when elem(hd(elem(node, 1)), 1) == :bernoulli
  
  defguard is_kw_breadth(node) when elem(hd(elem(node, 1)), 1) == :breadth
  
  defguard is_kw_c(node) when elem(hd(elem(node, 1)), 1) == :c
  
  defguard is_kw_cascade(node) when elem(hd(elem(node, 1)), 1) == :cascade
  
  defguard is_kw_catalog(node) when elem(hd(elem(node, 1)), 1) == :catalog
  
  defguard is_kw_catalog_name(node) when elem(hd(elem(node, 1)), 1) == :catalog_name
  
  defguard is_kw_chain(node) when elem(hd(elem(node, 1)), 1) == :chain
  
  defguard is_kw_chaining(node) when elem(hd(elem(node, 1)), 1) == :chaining
  
  defguard is_kw_character_set_catalog(node) when elem(hd(elem(node, 1)), 1) == :character_set_catalog
  
  defguard is_kw_character_set_name(node) when elem(hd(elem(node, 1)), 1) == :character_set_name
  
  defguard is_kw_character_set_schema(node) when elem(hd(elem(node, 1)), 1) == :character_set_schema
  
  defguard is_kw_characteristics(node) when elem(hd(elem(node, 1)), 1) == :characteristics
  
  defguard is_kw_characters(node) when elem(hd(elem(node, 1)), 1) == :characters
  
  defguard is_kw_class_origin(node) when elem(hd(elem(node, 1)), 1) == :class_origin
  
  defguard is_kw_cobol(node) when elem(hd(elem(node, 1)), 1) == :cobol
  
  defguard is_kw_collation(node) when elem(hd(elem(node, 1)), 1) == :collation
  
  defguard is_kw_collation_catalog(node) when elem(hd(elem(node, 1)), 1) == :collation_catalog
  
  defguard is_kw_collation_name(node) when elem(hd(elem(node, 1)), 1) == :collation_name
  
  defguard is_kw_collation_schema(node) when elem(hd(elem(node, 1)), 1) == :collation_schema
  
  defguard is_kw_columns(node) when elem(hd(elem(node, 1)), 1) == :columns
  
  defguard is_kw_column_name(node) when elem(hd(elem(node, 1)), 1) == :column_name
  
  defguard is_kw_command_function(node) when elem(hd(elem(node, 1)), 1) == :command_function
  
  defguard is_kw_command_function_code(node) when elem(hd(elem(node, 1)), 1) == :command_function_code
  
  defguard is_kw_committed(node) when elem(hd(elem(node, 1)), 1) == :committed
  
  defguard is_kw_conditional(node) when elem(hd(elem(node, 1)), 1) == :conditional
  
  defguard is_kw_condition_number(node) when elem(hd(elem(node, 1)), 1) == :condition_number
  
  defguard is_kw_connection(node) when elem(hd(elem(node, 1)), 1) == :connection
  
  defguard is_kw_connection_name(node) when elem(hd(elem(node, 1)), 1) == :connection_name
  
  defguard is_kw_constraint_catalog(node) when elem(hd(elem(node, 1)), 1) == :constraint_catalog
  
  defguard is_kw_constraint_name(node) when elem(hd(elem(node, 1)), 1) == :constraint_name
  
  defguard is_kw_constraint_schema(node) when elem(hd(elem(node, 1)), 1) == :constraint_schema
  
  defguard is_kw_constraints(node) when elem(hd(elem(node, 1)), 1) == :constraints
  
  defguard is_kw_constructor(node) when elem(hd(elem(node, 1)), 1) == :constructor
  
  defguard is_kw_continue(node) when elem(hd(elem(node, 1)), 1) == :continue
  
  defguard is_kw_copartition(node) when elem(hd(elem(node, 1)), 1) == :copartition
  
  defguard is_kw_cursor_name(node) when elem(hd(elem(node, 1)), 1) == :cursor_name
  
  defguard is_kw_data(node) when elem(hd(elem(node, 1)), 1) == :data
  
  defguard is_kw_datetime_interval_code(node) when elem(hd(elem(node, 1)), 1) == :datetime_interval_code
  
  defguard is_kw_datetime_interval_precision(node) when elem(hd(elem(node, 1)), 1) == :datetime_interval_precision
  
  defguard is_kw_defaults(node) when elem(hd(elem(node, 1)), 1) == :defaults
  
  defguard is_kw_deferrable(node) when elem(hd(elem(node, 1)), 1) == :deferrable
  
  defguard is_kw_deferred(node) when elem(hd(elem(node, 1)), 1) == :deferred
  
  defguard is_kw_defined(node) when elem(hd(elem(node, 1)), 1) == :defined
  
  defguard is_kw_definer(node) when elem(hd(elem(node, 1)), 1) == :definer
  
  defguard is_kw_degree(node) when elem(hd(elem(node, 1)), 1) == :degree
  
  defguard is_kw_depth(node) when elem(hd(elem(node, 1)), 1) == :depth
  
  defguard is_kw_derived(node) when elem(hd(elem(node, 1)), 1) == :derived
  
  defguard is_kw_desc(node) when elem(hd(elem(node, 1)), 1) == :desc
  
  defguard is_kw_descriptor(node) when elem(hd(elem(node, 1)), 1) == :descriptor
  
  defguard is_kw_diagnostics(node) when elem(hd(elem(node, 1)), 1) == :diagnostics
  
  defguard is_kw_dispatch(node) when elem(hd(elem(node, 1)), 1) == :dispatch
  
  defguard is_kw_domain(node) when elem(hd(elem(node, 1)), 1) == :domain
  
  defguard is_kw_dynamic_function(node) when elem(hd(elem(node, 1)), 1) == :dynamic_function
  
  defguard is_kw_dynamic_function_code(node) when elem(hd(elem(node, 1)), 1) == :dynamic_function_code
  
  defguard is_kw_encoding(node) when elem(hd(elem(node, 1)), 1) == :encoding
  
  defguard is_kw_enforced(node) when elem(hd(elem(node, 1)), 1) == :enforced
  
  defguard is_kw_error(node) when elem(hd(elem(node, 1)), 1) == :error
  
  defguard is_kw_exclude(node) when elem(hd(elem(node, 1)), 1) == :exclude
  
  defguard is_kw_excluding(node) when elem(hd(elem(node, 1)), 1) == :excluding
  
  defguard is_kw_expression(node) when elem(hd(elem(node, 1)), 1) == :expression
  
  defguard is_kw_final(node) when elem(hd(elem(node, 1)), 1) == :final
  
  defguard is_kw_finish(node) when elem(hd(elem(node, 1)), 1) == :finish
  
  defguard is_kw_first(node) when elem(hd(elem(node, 1)), 1) == :first
  
  defguard is_kw_following(node) when elem(hd(elem(node, 1)), 1) == :following
  
  defguard is_kw_format(node) when elem(hd(elem(node, 1)), 1) == :format
  
  defguard is_kw_fortran(node) when elem(hd(elem(node, 1)), 1) == :fortran
  
  defguard is_kw_found(node) when elem(hd(elem(node, 1)), 1) == :found
  
  defguard is_kw_fulfill(node) when elem(hd(elem(node, 1)), 1) == :fulfill
  
  defguard is_kw_g(node) when elem(hd(elem(node, 1)), 1) == :g
  
  defguard is_kw_general(node) when elem(hd(elem(node, 1)), 1) == :general
  
  defguard is_kw_generated(node) when elem(hd(elem(node, 1)), 1) == :generated
  
  defguard is_kw_go(node) when elem(hd(elem(node, 1)), 1) == :go
  
  defguard is_kw_goto(node) when elem(hd(elem(node, 1)), 1) == :goto
  
  defguard is_kw_granted(node) when elem(hd(elem(node, 1)), 1) == :granted
  
  defguard is_kw_hierarchy(node) when elem(hd(elem(node, 1)), 1) == :hierarchy
  
  defguard is_kw_ignore(node) when elem(hd(elem(node, 1)), 1) == :ignore
  
  defguard is_kw_immediate(node) when elem(hd(elem(node, 1)), 1) == :immediate
  
  defguard is_kw_immediately(node) when elem(hd(elem(node, 1)), 1) == :immediately
  
  defguard is_kw_implementation(node) when elem(hd(elem(node, 1)), 1) == :implementation
  
  defguard is_kw_including(node) when elem(hd(elem(node, 1)), 1) == :including
  
  defguard is_kw_increment(node) when elem(hd(elem(node, 1)), 1) == :increment
  
  defguard is_kw_initially(node) when elem(hd(elem(node, 1)), 1) == :initially
  
  defguard is_kw_input(node) when elem(hd(elem(node, 1)), 1) == :input
  
  defguard is_kw_instance(node) when elem(hd(elem(node, 1)), 1) == :instance
  
  defguard is_kw_instantiable(node) when elem(hd(elem(node, 1)), 1) == :instantiable
  
  defguard is_kw_instead(node) when elem(hd(elem(node, 1)), 1) == :instead
  
  defguard is_kw_invoker(node) when elem(hd(elem(node, 1)), 1) == :invoker
  
  defguard is_kw_isolation(node) when elem(hd(elem(node, 1)), 1) == :isolation
  
  defguard is_kw_k(node) when elem(hd(elem(node, 1)), 1) == :k
  
  defguard is_kw_keep(node) when elem(hd(elem(node, 1)), 1) == :keep
  
  defguard is_kw_key(node) when elem(hd(elem(node, 1)), 1) == :key
  
  defguard is_kw_keys(node) when elem(hd(elem(node, 1)), 1) == :keys
  
  defguard is_kw_key_member(node) when elem(hd(elem(node, 1)), 1) == :key_member
  
  defguard is_kw_key_type(node) when elem(hd(elem(node, 1)), 1) == :key_type
  
  defguard is_kw_length(node) when elem(hd(elem(node, 1)), 1) == :length
  
  defguard is_kw_level(node) when elem(hd(elem(node, 1)), 1) == :level
  
  defguard is_kw_locator(node) when elem(hd(elem(node, 1)), 1) == :locator
  
  defguard is_kw_m(node) when elem(hd(elem(node, 1)), 1) == :m
  
  defguard is_kw_map(node) when elem(hd(elem(node, 1)), 1) == :map
  
  defguard is_kw_matched(node) when elem(hd(elem(node, 1)), 1) == :matched
  
  defguard is_kw_maxvalue(node) when elem(hd(elem(node, 1)), 1) == :maxvalue
  
  defguard is_kw_measures(node) when elem(hd(elem(node, 1)), 1) == :measures
  
  defguard is_kw_message_length(node) when elem(hd(elem(node, 1)), 1) == :message_length
  
  defguard is_kw_message_octet_length(node) when elem(hd(elem(node, 1)), 1) == :message_octet_length
  
  defguard is_kw_message_text(node) when elem(hd(elem(node, 1)), 1) == :message_text
  
  defguard is_kw_minvalue(node) when elem(hd(elem(node, 1)), 1) == :minvalue
  
  defguard is_kw_more(node) when elem(hd(elem(node, 1)), 1) == :more
  
  defguard is_kw_mumps(node) when elem(hd(elem(node, 1)), 1) == :mumps
  
  defguard is_kw_name(node) when elem(hd(elem(node, 1)), 1) == :name
  
  defguard is_kw_names(node) when elem(hd(elem(node, 1)), 1) == :names
  
  defguard is_kw_nested(node) when elem(hd(elem(node, 1)), 1) == :nested
  
  defguard is_kw_nesting(node) when elem(hd(elem(node, 1)), 1) == :nesting
  
  defguard is_kw_next(node) when elem(hd(elem(node, 1)), 1) == :next
  
  defguard is_kw_nfc(node) when elem(hd(elem(node, 1)), 1) == :nfc
  
  defguard is_kw_nfd(node) when elem(hd(elem(node, 1)), 1) == :nfd
  
  defguard is_kw_nfkc(node) when elem(hd(elem(node, 1)), 1) == :nfkc
  
  defguard is_kw_nfkd(node) when elem(hd(elem(node, 1)), 1) == :nfkd
  
  defguard is_kw_normalized(node) when elem(hd(elem(node, 1)), 1) == :normalized
  
  defguard is_kw_null_ordering(node) when elem(hd(elem(node, 1)), 1) == :null_ordering
  
  defguard is_kw_nullable(node) when elem(hd(elem(node, 1)), 1) == :nullable
  
  defguard is_kw_nulls(node) when elem(hd(elem(node, 1)), 1) == :nulls
  
  defguard is_kw_object(node) when elem(hd(elem(node, 1)), 1) == :object
  
  defguard is_kw_occurrence(node) when elem(hd(elem(node, 1)), 1) == :occurrence
  
  defguard is_kw_octets(node) when elem(hd(elem(node, 1)), 1) == :octets
  
  defguard is_kw_option(node) when elem(hd(elem(node, 1)), 1) == :option
  
  defguard is_kw_options(node) when elem(hd(elem(node, 1)), 1) == :options
  
  defguard is_kw_ordering(node) when elem(hd(elem(node, 1)), 1) == :ordering
  
  defguard is_kw_ordinality(node) when elem(hd(elem(node, 1)), 1) == :ordinality
  
  defguard is_kw_others(node) when elem(hd(elem(node, 1)), 1) == :others
  
  defguard is_kw_output(node) when elem(hd(elem(node, 1)), 1) == :output
  
  defguard is_kw_overflow(node) when elem(hd(elem(node, 1)), 1) == :overflow
  
  defguard is_kw_overriding(node) when elem(hd(elem(node, 1)), 1) == :overriding
  
  defguard is_kw_p(node) when elem(hd(elem(node, 1)), 1) == :p
  
  defguard is_kw_pad(node) when elem(hd(elem(node, 1)), 1) == :pad
  
  defguard is_kw_parameter_mode(node) when elem(hd(elem(node, 1)), 1) == :parameter_mode
  
  defguard is_kw_parameter_name(node) when elem(hd(elem(node, 1)), 1) == :parameter_name
  
  defguard is_kw_parameter_ordinal_position(node) when elem(hd(elem(node, 1)), 1) == :parameter_ordinal_position
  
  defguard is_kw_parameter_specific_catalog(node) when elem(hd(elem(node, 1)), 1) == :parameter_specific_catalog
  
  defguard is_kw_parameter_specific_name(node) when elem(hd(elem(node, 1)), 1) == :parameter_specific_name
  
  defguard is_kw_parameter_specific_schema(node) when elem(hd(elem(node, 1)), 1) == :parameter_specific_schema
  
  defguard is_kw_partial(node) when elem(hd(elem(node, 1)), 1) == :partial
  
  defguard is_kw_pascal(node) when elem(hd(elem(node, 1)), 1) == :pascal
  
  defguard is_kw_pass(node) when elem(hd(elem(node, 1)), 1) == :pass
  
  defguard is_kw_passing(node) when elem(hd(elem(node, 1)), 1) == :passing
  
  defguard is_kw_past(node) when elem(hd(elem(node, 1)), 1) == :past
  
  defguard is_kw_path(node) when elem(hd(elem(node, 1)), 1) == :path
  
  defguard is_kw_permute(node) when elem(hd(elem(node, 1)), 1) == :permute
  
  defguard is_kw_pipe(node) when elem(hd(elem(node, 1)), 1) == :pipe
  
  defguard is_kw_placing(node) when elem(hd(elem(node, 1)), 1) == :placing
  
  defguard is_kw_plan(node) when elem(hd(elem(node, 1)), 1) == :plan
  
  defguard is_kw_pli(node) when elem(hd(elem(node, 1)), 1) == :pli
  
  defguard is_kw_preceding(node) when elem(hd(elem(node, 1)), 1) == :preceding
  
  defguard is_kw_preserve(node) when elem(hd(elem(node, 1)), 1) == :preserve
  
  defguard is_kw_prev(node) when elem(hd(elem(node, 1)), 1) == :prev
  
  defguard is_kw_prior(node) when elem(hd(elem(node, 1)), 1) == :prior
  
  defguard is_kw_private(node) when elem(hd(elem(node, 1)), 1) == :private
  
  defguard is_kw_privileges(node) when elem(hd(elem(node, 1)), 1) == :privileges
  
  defguard is_kw_prune(node) when elem(hd(elem(node, 1)), 1) == :prune
  
  defguard is_kw_public(node) when elem(hd(elem(node, 1)), 1) == :public
  
  defguard is_kw_quotes(node) when elem(hd(elem(node, 1)), 1) == :quotes
  
  defguard is_kw_read(node) when elem(hd(elem(node, 1)), 1) == :read
  
  defguard is_kw_relative(node) when elem(hd(elem(node, 1)), 1) == :relative
  
  defguard is_kw_repeatable(node) when elem(hd(elem(node, 1)), 1) == :repeatable
  
  defguard is_kw_respect(node) when elem(hd(elem(node, 1)), 1) == :respect
  
  defguard is_kw_restart(node) when elem(hd(elem(node, 1)), 1) == :restart
  
  defguard is_kw_restrict(node) when elem(hd(elem(node, 1)), 1) == :restrict
  
  defguard is_kw_returned_cardinality(node) when elem(hd(elem(node, 1)), 1) == :returned_cardinality
  
  defguard is_kw_returned_length(node) when elem(hd(elem(node, 1)), 1) == :returned_length
  
  defguard is_kw_returned_octet_length(node) when elem(hd(elem(node, 1)), 1) == :returned_octet_length
  
  defguard is_kw_returned_sqlstate(node) when elem(hd(elem(node, 1)), 1) == :returned_sqlstate
  
  defguard is_kw_returning(node) when elem(hd(elem(node, 1)), 1) == :returning
  
  defguard is_kw_role(node) when elem(hd(elem(node, 1)), 1) == :role
  
  defguard is_kw_routine(node) when elem(hd(elem(node, 1)), 1) == :routine
  
  defguard is_kw_routine_catalog(node) when elem(hd(elem(node, 1)), 1) == :routine_catalog
  
  defguard is_kw_routine_name(node) when elem(hd(elem(node, 1)), 1) == :routine_name
  
  defguard is_kw_routine_schema(node) when elem(hd(elem(node, 1)), 1) == :routine_schema
  
  defguard is_kw_row_count(node) when elem(hd(elem(node, 1)), 1) == :row_count
  
  defguard is_kw_scalar(node) when elem(hd(elem(node, 1)), 1) == :scalar
  
  defguard is_kw_scale(node) when elem(hd(elem(node, 1)), 1) == :scale
  
  defguard is_kw_schema(node) when elem(hd(elem(node, 1)), 1) == :schema
  
  defguard is_kw_schema_name(node) when elem(hd(elem(node, 1)), 1) == :schema_name
  
  defguard is_kw_scope_catalog(node) when elem(hd(elem(node, 1)), 1) == :scope_catalog
  
  defguard is_kw_scope_name(node) when elem(hd(elem(node, 1)), 1) == :scope_name
  
  defguard is_kw_scope_schema(node) when elem(hd(elem(node, 1)), 1) == :scope_schema
  
  defguard is_kw_section(node) when elem(hd(elem(node, 1)), 1) == :section
  
  defguard is_kw_security(node) when elem(hd(elem(node, 1)), 1) == :security
  
  defguard is_kw_self(node) when elem(hd(elem(node, 1)), 1) == :self
  
  defguard is_kw_semantics(node) when elem(hd(elem(node, 1)), 1) == :semantics
  
  defguard is_kw_sequence(node) when elem(hd(elem(node, 1)), 1) == :sequence
  
  defguard is_kw_serializable(node) when elem(hd(elem(node, 1)), 1) == :serializable
  
  defguard is_kw_server_name(node) when elem(hd(elem(node, 1)), 1) == :server_name
  
  defguard is_kw_session(node) when elem(hd(elem(node, 1)), 1) == :session
  
  defguard is_kw_sets(node) when elem(hd(elem(node, 1)), 1) == :sets
  
  defguard is_kw_simple(node) when elem(hd(elem(node, 1)), 1) == :simple
  
  defguard is_kw_sort_direction(node) when elem(hd(elem(node, 1)), 1) == :sort_direction
  
  defguard is_kw_source(node) when elem(hd(elem(node, 1)), 1) == :source
  
  defguard is_kw_space(node) when elem(hd(elem(node, 1)), 1) == :space
  
  defguard is_kw_specific_name(node) when elem(hd(elem(node, 1)), 1) == :specific_name
  
  defguard is_kw_state(node) when elem(hd(elem(node, 1)), 1) == :state
  
  defguard is_kw_statement(node) when elem(hd(elem(node, 1)), 1) == :statement
  
  defguard is_kw_structure(node) when elem(hd(elem(node, 1)), 1) == :structure
  
  defguard is_kw_style(node) when elem(hd(elem(node, 1)), 1) == :style
  
  defguard is_kw_subclass_origin(node) when elem(hd(elem(node, 1)), 1) == :subclass_origin
  
  defguard is_kw_t(node) when elem(hd(elem(node, 1)), 1) == :t
  
  defguard is_kw_table_name(node) when elem(hd(elem(node, 1)), 1) == :table_name
  
  defguard is_kw_temporary(node) when elem(hd(elem(node, 1)), 1) == :temporary
  
  defguard is_kw_through(node) when elem(hd(elem(node, 1)), 1) == :through
  
  defguard is_kw_ties(node) when elem(hd(elem(node, 1)), 1) == :ties
  
  defguard is_kw_top_level_count(node) when elem(hd(elem(node, 1)), 1) == :top_level_count
  
  defguard is_kw_transaction(node) when elem(hd(elem(node, 1)), 1) == :transaction
  
  defguard is_kw_transaction_active(node) when elem(hd(elem(node, 1)), 1) == :transaction_active
  
  defguard is_kw_transactions_committed(node) when elem(hd(elem(node, 1)), 1) == :transactions_committed
  
  defguard is_kw_transactions_rolled_back(node) when elem(hd(elem(node, 1)), 1) == :transactions_rolled_back
  
  defguard is_kw_transform(node) when elem(hd(elem(node, 1)), 1) == :transform
  
  defguard is_kw_transforms(node) when elem(hd(elem(node, 1)), 1) == :transforms
  
  defguard is_kw_trigger_catalog(node) when elem(hd(elem(node, 1)), 1) == :trigger_catalog
  
  defguard is_kw_trigger_name(node) when elem(hd(elem(node, 1)), 1) == :trigger_name
  
  defguard is_kw_trigger_schema(node) when elem(hd(elem(node, 1)), 1) == :trigger_schema
  
  defguard is_kw_unbounded(node) when elem(hd(elem(node, 1)), 1) == :unbounded
  
  defguard is_kw_uncommitted(node) when elem(hd(elem(node, 1)), 1) == :uncommitted
  
  defguard is_kw_unconditional(node) when elem(hd(elem(node, 1)), 1) == :unconditional
  
  defguard is_kw_under(node) when elem(hd(elem(node, 1)), 1) == :under
  
  defguard is_kw_unmatched(node) when elem(hd(elem(node, 1)), 1) == :unmatched
  
  defguard is_kw_unnamed(node) when elem(hd(elem(node, 1)), 1) == :unnamed
  
  defguard is_kw_usage(node) when elem(hd(elem(node, 1)), 1) == :usage
  
  defguard is_kw_user_defined_type_catalog(node) when elem(hd(elem(node, 1)), 1) == :user_defined_type_catalog
  
  defguard is_kw_user_defined_type_code(node) when elem(hd(elem(node, 1)), 1) == :user_defined_type_code
  
  defguard is_kw_user_defined_type_name(node) when elem(hd(elem(node, 1)), 1) == :user_defined_type_name
  
  defguard is_kw_user_defined_type_schema(node) when elem(hd(elem(node, 1)), 1) == :user_defined_type_schema
  
  defguard is_kw_utf16(node) when elem(hd(elem(node, 1)), 1) == :utf16
  
  defguard is_kw_utf32(node) when elem(hd(elem(node, 1)), 1) == :utf32
  
  defguard is_kw_utf8(node) when elem(hd(elem(node, 1)), 1) == :utf8
  
  defguard is_kw_view(node) when elem(hd(elem(node, 1)), 1) == :view
  
  defguard is_kw_work(node) when elem(hd(elem(node, 1)), 1) == :work
  
  defguard is_kw_wrapper(node) when elem(hd(elem(node, 1)), 1) == :wrapper
  
  defguard is_kw_write(node) when elem(hd(elem(node, 1)), 1) == :write
  
  defguard is_kw_zone(node) when elem(hd(elem(node, 1)), 1) == :zone
  

  
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
  
  
  def tag([[[[], ?^], ?-], ?=]), do: :"^-="
  
  def tag([[[[], ?<], ?=], ?>]), do: :"<=>"
  
  def tag([[[[], ?-], ?>], ?>]), do: :"->>"
  
  def tag([[[[], ?|], ?|], ?/]), do: :"||/"
  
  def tag([[[[], ?!], ?~], ?*]), do: :"!~*"
  
  def tag([[[[], ?<], ?<], ?|]), do: :"<<|"
  
  def tag([[[[], ?|], ?>], ?>]), do: :"|>>"
  
  def tag([[[[], ?&], ?<], ?|]), do: :"&<|"
  
  def tag([[[[], ?|], ?&], ?>]), do: :"|&>"
  
  def tag([[[[], ??], ?-], ?|]), do: :"?-|"
  
  def tag([[[[], ??], ?|], ?|]), do: :"?||"
  
  def tag([[[[], ?<], ?<], ?=]), do: :"<<="
  
  def tag([[[[], ?>], ?>], ?=]), do: :">>="
  
  def tag([[[[], ?#], ?>], ?>]), do: :"#>>"
  
  def tag([[[[], ?-], ?|], ?-]), do: :"-|-"
  
  def tag([[[], ?&], ?&]), do: :&&
  
  def tag([[[], ?|], ?|]), do: :||
  
  def tag([[[], ?&], ?=]), do: :"&="
  
  def tag([[[], ?^], ?=]), do: :"^="
  
  def tag([[[], ?|], ?=]), do: :"|="
  
  def tag([[[[], ?|], ?*], ?=]), do: :"|*="
  
  def tag([[[], ?>], ?>]), do: :">>"
  
  def tag([[[], ?<], ?<]), do: :"<<"
  
  def tag([[[], ?-], ?>]), do: :->
  
  def tag([[[], ?:], ?=]), do: :":="
  
  def tag([[[], ?+], ?=]), do: :"+="
  
  def tag([[[], ?-], ?=]), do: :"-="
  
  def tag([[[], ?*], ?=]), do: :"*="
  
  def tag([[[], ?/], ?=]), do: :"/="
  
  def tag([[[], ?%], ?=]), do: :"%="
  
  def tag([[[], ?!], ?>]), do: :"!>"
  
  def tag([[[], ?!], ?<]), do: :"!<"
  
  def tag([[[], ?@], ?>]), do: :"@>"
  
  def tag([[[], ?<], ?@]), do: :"<@"
  
  def tag([[[], ?|], ?/]), do: :"|/"
  
  def tag([[[], ?^], ?@]), do: :"^@"
  
  def tag([[[], ?~], ?*]), do: :"~*"
  
  def tag([[[], ?!], ?~]), do: :"!~"
  
  def tag([[[], ?#], ?#]), do: :"##"
  
  def tag([[[], ?&], ?<]), do: :"&<"
  
  def tag([[[], ?&], ?>]), do: :"&>"
  
  def tag([[[], ?<], ?^]), do: :"<^"
  
  def tag([[[], ?>], ?^]), do: :">^"
  
  def tag([[[], ??], ?#]), do: :"?#"
  
  def tag([[[], ??], ?-]), do: :"?-"
  
  def tag([[[], ??], ?|]), do: :"?|"
  
  def tag([[[], ?~], ?=]), do: :"~="
  
  def tag([[[], ?@], ?@]), do: :"@@"
  
  def tag([[[], ?!], ?!]), do: :"!!"
  
  def tag([[[], ?#], ?>]), do: :"#>"
  
  def tag([[[], ??], ?&]), do: :"?&"
  
  def tag([[[], ?#], ?-]), do: :"#-"
  
  def tag([[[], ?@], ??]), do: :"@?"
  
  def tag([[[], ?:], ?:]), do: :"::"
  
  def tag([[[], ?<], ?>]), do: :<>
  
  def tag([[[], ?>], ?=]), do: :>=
  
  def tag([[[], ?<], ?=]), do: :<=
  
  def tag([[[], ?!], ?=]), do: :!=
  
  def tag([[], ?+]), do: :+
  
  def tag([[], ?-]), do: :-
  
  def tag([[], ?!]), do: :!
  
  def tag([[], ?&]), do: :&
  
  def tag([[], ?^]), do: :^
  
  def tag([[], ?|]), do: :|
  
  def tag([[], ?~]), do: :"~"
  
  def tag([[], ?%]), do: :%
  
  def tag([[], ?@]), do: :@
  
  def tag([[], ?#]), do: :"#"
  
  def tag([[], ?*]), do: :*
  
  def tag([[], ?/]), do: :/
  
  def tag([[], ?=]), do: :=
  
  def tag([[], ?>]), do: :>
  
  def tag([[], ?<]), do: :<
  
  def tag(_), do: nil
end
