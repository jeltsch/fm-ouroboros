section \<open>Foundations\<close>

theory "Thorn_Calculus-Foundations"
imports
  Main
  "HOL-Library.Stream"
begin

subsection \<open>Channels and Values\<close>

typedecl chan

axiomatization where
  more_than_one_chan:
    "\<exists>a b :: chan. a \<noteq> b"

typedecl val

subsection \<open>Environments\<close>

type_synonym environment = "chan stream"

text \<open>
  Regarding the naming, note that \<^const>\<open>insert\<close> is already taken. For adaptations, we do not use
  the \<open>_at\<close> suffix and thus have \<open>remove\<close> as the equivalent of \<open>delete_at\<close>.
\<close>

definition insert_at :: "nat \<Rightarrow> chan \<Rightarrow> environment \<Rightarrow> environment" where
  [simp]: "insert_at i a e = stake i e @- a ## sdrop i e"

definition delete_at :: "nat \<Rightarrow> environment \<Rightarrow> environment" where
  [simp]: "delete_at i e = stake i e @- sdrop (Suc i) e"

lemma insert_at_after_delete_at:
  shows "insert_at i (e !! i) (delete_at i e) = e"
  by (simp del: sdrop.simps(2) add: stake_shift sdrop_shift id_stake_snth_sdrop [symmetric])

lemma delete_at_after_insert_at:
  shows "delete_at i (insert_at i a e) = e"
  by (simp add: stake_append sdrop_shift stake_sdrop)

subsection \<open>Families\<close>

type_synonym 'a family = "environment \<Rightarrow> 'a"

abbreviation constant_family :: "'a \<Rightarrow> 'a family" (\<open>(\<langle>_\<rangle>)\<close>) where
  "\<langle>v\<rangle> \<equiv> (\<lambda>_. v)"

definition family_curry :: "'a family \<Rightarrow> (chan \<Rightarrow> 'a family)" (\<open>\<Delta>\<close>) where
  [simp]: "\<Delta> V = (\<lambda>a. \<lambda>e. V (a ## e))"

definition family_uncurry :: "(chan \<Rightarrow> 'a family) \<Rightarrow> 'a family" (\<open>\<nabla>\<close>) where
  [simp]: "\<nabla> \<V> = (\<lambda>e. \<V> (shd e) (stl e))"

definition deep_curry :: "nat \<Rightarrow> 'a family \<Rightarrow> (chan \<Rightarrow> 'a family)" (\<open>(\<Delta>\<^bsub>_\<^esub>)\<close>) where
  [simp]: "\<Delta>\<^bsub>i\<^esub> V = (\<lambda>a. \<lambda>e. V (insert_at i a e))"

definition deep_uncurry :: "nat \<Rightarrow> (chan \<Rightarrow> 'a family) \<Rightarrow> 'a family" (\<open>(\<nabla>\<^bsub>_\<^esub>)\<close>) where
  [simp]: "\<nabla>\<^bsub>i\<^esub> \<V> = (\<lambda>e. \<V> (e !! i) (delete_at i e))"

subsection \<open>Adaptations\<close>

typedef adaptation = "{E :: environment \<Rightarrow> environment. surj E}"
  by auto

text \<open>
  Surjectivity is needed for the following:

    \<^item> \<^theory_text>\<open>adapted_injectivity\<close>, used here:

        \<^item> Pre-simplification in proofs with concrete process families (well, the adaptations used in
          the transition system \<^emph>\<open>are\<close> surjective; the above surjectivity requirement just kind of
          centralizes the handling of the surjectivity of all of them

        \<^item> Handling of the ``non-constant'' requirement of the \<^theory_text>\<open>opening\<close> rule in that lemma on
          equivalence of transitions with transitions containing adaption

    \<^item> Deriving of the backward implication from the forward implication in the above-mentioned
      lemma
\<close>
(* FIXME: Check if there are more. *)

notation Rep_adaptation (\<open>(\<lfloor>_\<rfloor>)\<close>)

setup_lifting type_definition_adaptation

lift_definition adaptation_identity :: adaptation (\<open>\<one>\<close>)
  is id
  using surj_id .

lift_definition adaptation_composition :: "adaptation \<Rightarrow> adaptation \<Rightarrow> adaptation" (infixl "\<bullet>" 55)
  is "(\<circ>)"
  using comp_surj .

lemma adaptation_composition_associativity:
  shows "(\<E> \<bullet> \<D>) \<bullet> \<C> = \<E> \<bullet> (\<D> \<bullet> \<C>)"
  by transfer (rule comp_assoc)

lift_definition injective :: "adaptation \<Rightarrow> bool"
  is inj .

lemma injective_introduction:
  assumes "\<D> \<bullet> \<E> = \<one>"
  shows "injective \<E>"
  using assms
  by transfer (metis inj_on_id inj_on_imageI2)

text \<open>
  The following elimination rule captures two important properties:

    \<^item> The left inverse of an injective adaptation is surjective and thus and adaptation itself.

    \<^item> The left inverse of an injective adaptation is also a right inverse.
\<close>

lemma injective_elimination:
  assumes "injective \<E>"
  obtains \<D> where "\<D> \<bullet> \<E> = \<one>" and "\<E> \<bullet> \<D> = \<one>"
proof -
  from \<open>injective \<E>\<close> have "bijection \<lfloor>\<E>\<rfloor>"
    unfolding bijection_def
    by transfer (rule bijI)
  then have "surj (inv \<lfloor>\<E>\<rfloor>)" and "inv \<lfloor>\<E>\<rfloor> \<circ> \<lfloor>\<E>\<rfloor> = id" and "\<lfloor>\<E>\<rfloor> \<circ> inv \<lfloor>\<E>\<rfloor> = id"
    by (fact bijection.surj_inv, fact bijection.inv_comp_left, fact bijection.inv_comp_right)
  with that show ?thesis
    by transfer simp 
qed

lemma identity_is_injective:
  shows "injective \<one>"
  by transfer simp

lift_definition adapted :: "'a family \<Rightarrow> adaptation \<Rightarrow> 'a family" (infixl "\<guillemotleft>" 55)
  is "(\<circ>)" .

lemma identity_adapted:
  shows "V \<guillemotleft> \<one> = V"
  by transfer simp

lemma composition_adapted:
  shows "V \<guillemotleft> (\<E> \<bullet> \<D>) = V \<guillemotleft> \<E> \<guillemotleft> \<D>"
  by transfer (simp add: comp_assoc)

lemma adapted_undo:
  shows "V \<guillemotleft> \<E> \<circ> inv \<lfloor>\<E>\<rfloor> = V"
  by transfer (simp add: comp_assoc surj_iff)

text \<open>
  The following is not just a pre-simplification rules but a very important law, used as a
  simplification rule in several places. See above for the arguments in favor of surjectivity.
\<close>

lemma adapted_injectivity [induct_simp, iff]:
  shows "V \<guillemotleft> \<E> = W \<guillemotleft> \<E> \<longleftrightarrow> V = W"
proof
  assume "V \<guillemotleft> \<E> = W \<guillemotleft> \<E>"
  then have "V \<guillemotleft> \<E> \<circ> inv \<lfloor>\<E>\<rfloor> = W \<guillemotleft> \<E> \<circ> inv \<lfloor>\<E>\<rfloor>"
    by simp
  then show "V = W"
    unfolding adapted_undo .
next
  assume "V = W"
  then show "V \<guillemotleft> \<E> = W \<guillemotleft> \<E>"
    by simp
qed

subsubsection \<open>Working with Elements\<close>

lift_definition remove :: "nat \<Rightarrow> adaptation"
  is delete_at
proof (rule surjI)
  fix n and e'
  show "delete_at n (insert_at n undefined e') = e'"
    using delete_at_after_insert_at .
qed

lift_definition move :: "nat \<Rightarrow> nat \<Rightarrow> adaptation"
  is "\<lambda>i j. \<lambda>e. insert_at j (e !! i) (delete_at i e)"
proof (rule surjI)
  fix i and j and e'
  show "(\<lambda>e. insert_at j (e !! i) (delete_at i e)) (insert_at i (e' !! j) (delete_at j e')) = e'"
    \<comment> \<open>This is essentially the statement of \<^theory_text>\<open>back_and_forth_move\<close> below.\<close>
    using delete_at_after_insert_at and insert_at_after_delete_at
    by simp
qed

lemma identity_as_move:
  shows "\<one> = move i i"
  using insert_at_after_delete_at
  by transfer (simp add: id_def)

lemma composition_as_move:
  shows "move j k \<bullet> move i j = move i k"
  using delete_at_after_insert_at
  by transfer auto

lemma back_and_forth_move:
  shows "move j i \<bullet> move i j = \<one>"
  using composition_as_move and identity_as_move [symmetric]
  by simp

lemma move_is_injective:
  shows "injective (move i j)"
  using back_and_forth_move
  by (rule injective_introduction)

subsubsection \<open>Working with Suffixes\<close>

lift_definition suffix :: "nat \<Rightarrow> adaptation"
  is sdrop
proof (rule surjI)
  fix n and e'
  show "sdrop n (replicate n undefined @- e') = e'"
    by (simp add: sdrop_shift)
qed

definition tail :: adaptation where
  [simp]: "tail = suffix 1"

lemma move_after_suffix:
  shows "move i j \<bullet> suffix n = suffix n \<bullet> move (n + i) (n + j)"
  by
    (transfer fixing: i j, cases "i < j")
    (simp_all
      add: comp_def stake_shift sdrop_shift take_stake drop_stake min_absorb2 min_absorb1 sdrop_snth
    )

lift_definition on_suffix :: "nat \<Rightarrow> adaptation \<Rightarrow> adaptation"
  is "\<lambda>n E. \<lambda>e. stake n e @- E (sdrop n e)"
proof (rule surjI)
  fix n and E :: "environment \<Rightarrow> environment" and e'
  assume "surj E"
  then show "(\<lambda>e. stake n e @- E (sdrop n e)) (stake n e' @- inv E (sdrop n e')) = e'"
    by (simp add: stake_shift sdrop_shift surj_f_inv_f stake_sdrop)
qed

definition on_tail :: "adaptation \<Rightarrow> adaptation" where
  [simp]: "on_tail = on_suffix 1"

lemma identity_as_on_suffix:
  shows "\<one> = on_suffix n \<one>"
  by transfer (auto simp add: stake_sdrop)

lemma composition_as_on_suffix:
  shows "on_suffix n \<E> \<bullet> on_suffix n \<D> = on_suffix n (\<E> \<bullet> \<D>)"
  by transfer (simp add: comp_def stake_shift sdrop_shift)

lemma identity_as_partial_on_suffix:
  shows "id = on_suffix 0"
  by (rule ext, transfer) simp

lemma composition_as_partial_on_suffix:
  shows "on_suffix n \<circ> on_suffix m = on_suffix (n + m)"
  by (rule ext, transfer) (simp del: shift_append add: shift_append [symmetric])

lemma on_suffix_is_injective:
  assumes "injective \<E>"
  shows "injective (on_suffix n \<E>)"
proof -
  from \<open>injective \<E>\<close> obtain \<D> where "\<D> \<bullet> \<E> = \<one>"
    by (blast elim: injective_elimination)
  have "on_suffix n \<D> \<bullet> on_suffix n \<E> = on_suffix n (\<D> \<bullet> \<E>)"
    by transfer (simp add: comp_def stake_shift sdrop_shift)
  also have "\<dots> = on_suffix n \<one>"
    using \<open>\<D> \<bullet> \<E> = \<one>\<close>
    by simp
  also have "\<dots> = \<one>"
    by transfer (auto simp add: stake_sdrop)
  finally show ?thesis
    by (fact injective_introduction)
qed

lemma on_suffix_remove:
  shows "on_suffix n (remove i) = remove (n + i)"
  by transfer (auto simp del: shift_append simp add: shift_append [symmetric])

lemma suffix_after_on_suffix:
  shows "suffix n \<bullet> on_suffix n \<E> = \<E> \<bullet> suffix n"
  by transfer (simp add: comp_def sdrop_shift)

lemma remove_after_on_suffix:
  assumes "i \<le> n"
  shows "remove i \<bullet> on_suffix (Suc n) \<E> = on_suffix n \<E> \<bullet> remove i"
  using assms
  by
    (transfer fixing: i n)
    (simp
      del: stake.simps(2)
      add: comp_def stake_shift sdrop_shift take_stake drop_stake min_absorb1 min_absorb2
    )

context begin

private definition finite_insert_at :: "nat \<Rightarrow> chan \<Rightarrow> chan list \<Rightarrow> chan list" where
  [simp]: "finite_insert_at i a e = take i e @ a # drop i e"

private definition finite_delete_at :: "nat \<Rightarrow> chan list \<Rightarrow> chan list" where
  [simp]: "finite_delete_at i e = take i e @ drop (Suc i) e"

lemma move_after_on_suffix:
  assumes "i < n" and "j < n"
  shows "move i j \<bullet> on_suffix n \<E> = on_suffix n \<E> \<bullet> move i j"
proof -
  have "
    (\<lambda>e'. insert_at j (e' !! i) (delete_at i e')) (stake n e @- E (sdrop n e)) =
    (\<lambda>e'. stake n e' @- E (sdrop n e')) (insert_at j (e !! i) (delete_at i e))"
    (is "?e\<^sub>1 = ?e\<^sub>2")
    for E and e
  proof -
    \<comment> \<open>Turn \<^term>\<open>e' !! i\<close> into \<^term>\<open>e !! i\<close>:\<close>
    have "?e\<^sub>1 = insert_at j (e !! i) (delete_at i (stake n e @- E (sdrop n e)))"
      using \<open>i < n\<close>
      by simp
    \<comment> \<open>Push deletion and insertion into the prefix argument of \<^term>\<open>(@-)\<close>:\<close>
    also have "\<dots> = insert_at j (e !! i) (finite_delete_at i (stake n e) @- E (sdrop n e))"
      using \<open>i < n\<close>
      by (simp add: stake_shift sdrop_shift)
    also have "\<dots> = finite_insert_at j (e !! i) (finite_delete_at i (stake n e)) @- E (sdrop n e)"
      using \<open>j < n\<close>
      by (simp add: stake_shift sdrop_shift)
    \<comment> \<open>Push deletion and insertion into the stream argument of \<^const>\<open>stake\<close>:\<close>
    also note stake_push_rules = take_stake drop_stake stake_shift min_absorb1 min_absorb2
    have "\<dots> = finite_insert_at j (e !! i) (stake (n - 1) (delete_at i e)) @- E (sdrop n e)"
      using \<open>i < n\<close>
      by (simp add: stake_push_rules)
    also have "\<dots> = stake n (insert_at j (e !! i) (delete_at i e)) @- E (sdrop n e)"
      using \<open>j < n\<close>
      by (simp del: delete_at_def add: stake_push_rules Suc_diff_Suc [symmetric])
    \<comment> \<open>Turn \<^term>\<open>sdrop n e\<close> into \<^term>\<open>sdrop n e'\<close>:\<close>
    also have "\<dots> =
      stake n (insert_at j (e !! i) (delete_at i e)) @- E (sdrop (n - 1) (delete_at i e))"
      using \<open>i < n\<close>
      by (simp del: sdrop.simps(2) add: sdrop_shift drop_stake)
    also have "\<dots> = ?e\<^sub>2"
      using \<open>j < n\<close>
      by (simp del: delete_at_def add: sdrop_shift drop_stake Suc_diff_Suc [symmetric])
    \<comment> \<open>Put everything together:\<close>
    finally show ?thesis .
  qed
  then show ?thesis
    by transfer auto
qed

end

lemma family_curry_after_on_suffix_adapted:
  shows "\<Delta> (V \<guillemotleft> on_suffix (Suc n) \<E>) = (\<lambda>W. W \<guillemotleft> on_suffix n \<E>) \<circ> \<Delta> V"
  by transfer (simp add: comp_def)

lemma on_suffix_adapted_after_family_uncurry:
  shows "\<nabla> \<V> \<guillemotleft> on_suffix (Suc n) \<E> = \<nabla> ((\<lambda>W. W \<guillemotleft> on_suffix n \<E>) \<circ> \<V>)"
  by transfer (simp add: comp_def)

lemma deep_curry_after_on_suffix_adapted:
  assumes "i \<le> n"
  shows "\<Delta>\<^bsub>i\<^esub> (V \<guillemotleft> on_suffix (Suc n) \<E>) = (\<lambda>W. W \<guillemotleft> on_suffix n \<E>) \<circ> \<Delta>\<^bsub>i\<^esub> V"
proof -
  have "\<Delta>\<^bsub>i\<^esub> (V \<guillemotleft> on_suffix (Suc n) \<E>) = \<Delta> (V \<guillemotleft> on_suffix (Suc n) \<E> \<guillemotleft> move 0 i)"
    by transfer simp
  also have "\<dots> = \<Delta> (V \<guillemotleft> move 0 i \<guillemotleft> on_suffix (Suc n) \<E>)"
    using \<open>i \<le> n\<close>
    by (simp only: composition_adapted [symmetric] move_after_on_suffix)
  also have "\<dots> = (\<lambda>Y. Y \<guillemotleft> on_suffix n \<E>) \<circ> \<Delta> (V \<guillemotleft> move 0 i)"
    using family_curry_after_on_suffix_adapted .
  also have "\<dots> = (\<lambda>Y. Y \<guillemotleft> on_suffix n \<E>) \<circ> \<Delta>\<^bsub>i\<^esub> V"
    by transfer simp
  finally show ?thesis .
qed

lemma on_suffix_adapted_after_deep_uncurry:
  assumes "i \<le> n"
  shows "\<nabla>\<^bsub>i\<^esub> \<V> \<guillemotleft> on_suffix (Suc n) \<E> = \<nabla>\<^bsub>i\<^esub> ((\<lambda>W. W \<guillemotleft> on_suffix n \<E>) \<circ> \<V>)"
proof -
  have "\<nabla>\<^bsub>i\<^esub> \<V> \<guillemotleft> on_suffix (Suc n) \<E> = \<nabla> \<V> \<guillemotleft> move i 0 \<guillemotleft> on_suffix (Suc n) \<E>"
    by transfer (simp add: comp_def)
  also have "\<dots> = \<nabla> \<V> \<guillemotleft> on_suffix (Suc n) \<E> \<guillemotleft> move i 0"
    using \<open>i \<le> n\<close>
    by (simp only: composition_adapted [symmetric] move_after_on_suffix)
  also have "\<dots> = \<nabla> ((\<lambda>W. W \<guillemotleft> on_suffix n \<E>) \<circ> \<V>) \<guillemotleft> move i 0"
    by (simp only: on_suffix_adapted_after_family_uncurry)
  also have "\<dots> = \<nabla>\<^bsub>i\<^esub> ((\<lambda>W. W \<guillemotleft> on_suffix n \<E>) \<circ> \<V>)"
    by transfer (simp add: comp_def)
  finally show ?thesis .
qed

lemma suffix_adapted_and_on_suffix_adapted:
  assumes "V' \<guillemotleft> suffix n = W \<guillemotleft> on_suffix n \<E>"
  obtains V where "V' = V \<guillemotleft> \<E>" and "W = V \<guillemotleft> suffix n"
proof -
  have V'_definition: "V' = W \<circ> (\<lambda>e. replicate n undefined @- e) \<guillemotleft> \<E>"
  proof -
    have "V' = V' \<guillemotleft> suffix n \<circ> (\<lambda>e. replicate n undefined @- e)"
      by transfer (simp add: comp_def sdrop_shift)
    also have "\<dots> = W \<guillemotleft> on_suffix n \<E> \<circ> (\<lambda>e. replicate n undefined @- e)"
      by (simp only: assms)
    also have "\<dots> = W \<circ> (\<lambda>e. replicate n undefined @- e) \<guillemotleft> \<E>"
      by transfer (simp add: comp_def stake_shift sdrop_shift)
    finally show ?thesis.
  qed
  moreover
  have "W = W \<circ> (\<lambda>e. replicate n undefined @- e) \<guillemotleft> suffix n"
  proof -
    have "
      W \<circ> (@-) (replicate n undefined) \<guillemotleft> suffix n \<guillemotleft> on_suffix n \<E>
      =
      W \<circ> (@-) (replicate n undefined) \<guillemotleft> \<E> \<guillemotleft> suffix n"
      by transfer (simp_all add: comp_def sdrop_shift)
    also have "\<dots> = W \<guillemotleft> on_suffix n \<E>"
      using assms unfolding V'_definition . 
    finally show ?thesis
      by simp
  qed
  ultimately show ?thesis
    using that
    by blast
qed

lemma move_adapted_and_on_suffix_adapted:
  assumes "i < n" and "j < n" and "V' \<guillemotleft> move i j = W \<guillemotleft> on_suffix n \<E>"
  obtains V where "V' = V \<guillemotleft> on_suffix n \<E>" and "W = V \<guillemotleft> move i j"
proof -
  have "V' = W \<guillemotleft> move j i \<guillemotleft> on_suffix n \<E>"
  proof -
    have "V' = V' \<guillemotleft> move i j \<guillemotleft> move j i"
      by (simp only: composition_adapted [symmetric] back_and_forth_move identity_adapted)
    also have "\<dots> = W \<guillemotleft> on_suffix n \<E> \<guillemotleft> move j i"
      using \<open>V' \<guillemotleft> move i j = W \<guillemotleft> on_suffix n \<E>\<close>
      by simp
    also have "\<dots> = W \<guillemotleft> move j i \<guillemotleft> on_suffix n \<E>"
      using \<open>i < n\<close> and \<open>j < n\<close>
      by (simp only: composition_adapted [symmetric] move_after_on_suffix)
    finally show ?thesis .
  qed
  moreover have "W = W \<guillemotleft> move j i \<guillemotleft> move i j"
    by (simp only: composition_adapted [symmetric] back_and_forth_move identity_adapted)
  ultimately show ?thesis
    using that
    by blast
qed

lemma remove_adapted_and_on_suffix_adapted:
  assumes "i \<le> n" and "V' \<guillemotleft> remove i = W \<guillemotleft> on_suffix (Suc n) \<E>"
  obtains V where "V' = V \<guillemotleft> on_suffix n \<E>" and "W = V \<guillemotleft> remove i"
proof -
  from assms(2) have "V' \<guillemotleft> tail \<guillemotleft> move i 0 = W \<guillemotleft> on_suffix (Suc n) \<E>"
    unfolding tail_def
    by transfer (simp add: comp_def)
  then obtain V'' where "V' \<guillemotleft> tail = V'' \<guillemotleft> on_suffix (Suc n) \<E>" and "W = V'' \<guillemotleft> move i 0"
    using move_adapted_and_on_suffix_adapted [OF le_imp_less_Suc [OF \<open>i \<le> n\<close>]]
    by blast
  from this(1) have "V' \<guillemotleft> tail = V'' \<guillemotleft> on_tail (on_suffix n \<E>)"
    using composition_as_partial_on_suffix [THEN fun_cong]
    by simp
  then obtain V where "V' = V \<guillemotleft> on_suffix n \<E>" and "V'' = V \<guillemotleft> tail"
    unfolding tail_def and on_tail_def
    using suffix_adapted_and_on_suffix_adapted
    by blast
  from \<open>W = V'' \<guillemotleft> move i 0\<close> and \<open>V'' = V \<guillemotleft> tail\<close> have "W = V \<guillemotleft> remove i"
    unfolding tail_def
    by transfer (simp add: comp_def)
  with that and \<open>V' = V \<guillemotleft> on_suffix n \<E>\<close> show ?thesis .
qed

lemma family_uncurry_and_on_suffix_adapted:
  assumes "\<nabla> \<V>' = W \<guillemotleft> on_suffix (Suc n) \<E>"
  obtains \<V> where "\<V>' = ((\<lambda>V. V \<guillemotleft> on_suffix n \<E>) \<circ> \<V>)" and "W = \<nabla> \<V>"
proof -
  have "\<V>' = (\<lambda>W'. W' \<guillemotleft> on_suffix n \<E>) \<circ> \<Delta> W"
  proof -
    have "\<V>' = \<Delta> (\<nabla> \<V>')"
      by simp
    also have "\<dots> = \<Delta> (W \<guillemotleft> on_suffix (Suc n) \<E>)"
      using \<open>\<nabla> \<V>' = W \<guillemotleft> on_suffix (Suc n) \<E>\<close>
      by simp
    also have "\<dots> = (\<lambda>V. V \<guillemotleft> on_suffix n \<E>) \<circ> \<Delta> W"
      by (simp only: family_curry_after_on_suffix_adapted)
    finally show ?thesis .
  qed
  moreover have "W = \<nabla> (\<Delta> W)"
    by simp
  ultimately show ?thesis
    using that
    by blast
qed

lemma deep_uncurry_and_on_suffix_adapted:
  assumes "i \<le> n" and "\<nabla>\<^bsub>i\<^esub> \<V>' = W \<guillemotleft> on_suffix (Suc n) \<E>"
  obtains \<V> where "\<V>' = ((\<lambda>V. V \<guillemotleft> on_suffix n \<E>) \<circ> \<V>)" and "W = \<nabla>\<^bsub>i\<^esub> \<V>"
proof -
  from assms(2) have "\<nabla> \<V>' \<guillemotleft> move i 0 = W \<guillemotleft> on_suffix (Suc n) \<E>"
    by transfer (simp add: comp_def)
  then obtain V where "\<nabla> \<V>' = V \<guillemotleft> on_suffix (Suc n) \<E>" and "W = V \<guillemotleft> move i 0"
    using move_adapted_and_on_suffix_adapted [OF le_imp_less_Suc [OF \<open>i \<le> n\<close>]]
    by blast
  from this(1) obtain \<V> where "\<V>' = ((\<lambda>V. V \<guillemotleft> on_suffix n \<E>) \<circ> \<V>)" and "V = \<nabla> \<V>"
    using family_uncurry_and_on_suffix_adapted
    by blast
  from \<open>W = V \<guillemotleft> move i 0\<close> and \<open>V = \<nabla> \<V>\<close> have "W = \<nabla>\<^bsub>i\<^esub> \<V>"
    by transfer (simp add: comp_def)
  with that and \<open>\<V>' = ((\<lambda>V. V \<guillemotleft> on_suffix n \<E>) \<circ> \<V>)\<close> show ?thesis .
qed

lemma chan_family_distinctness [induct_simp, simp]:
  fixes A :: "chan family"
  shows "shd \<noteq> A \<guillemotleft> tail" and "A \<guillemotleft> tail \<noteq> shd"
proof -
  obtain a :: chan and b :: chan where "a \<noteq> b"
    using more_than_one_chan
    by blast
  then show "shd \<noteq> A \<guillemotleft> tail"
  proof (cases "A undefined = a")
    case True
    with \<open>a \<noteq> b\<close> have "shd (b ## undefined) \<noteq> (A \<guillemotleft> tail) (b ## undefined)"
      unfolding tail_def
      by transfer simp
    then show ?thesis
      by auto
  next
    case False
    then have "shd (a ## undefined) \<noteq> (A \<guillemotleft> tail) (a ## undefined)"
      unfolding tail_def
      by transfer simp
    then show ?thesis
      by auto
  qed
  then show "A \<guillemotleft> tail \<noteq> shd"
    by simp
qed

end