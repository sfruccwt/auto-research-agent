# Opening note v2 模板

## origin_context

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 58%;">
    <col style="width: 20%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">field</th>
      <th align="left">填写说明</th>
      <th align="left">填写</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>raw_input</td>
      <td>原始输入。若来自 <code>idea.md</code>，填写文件路径或链接；若来自用户口述，填写原文。</td>
      <td></td>
    </tr>
  </tbody>
</table>

## inquiry_shape

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 58%;">
    <col style="width: 20%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">field</th>
      <th align="left">填写说明</th>
      <th align="left">填写</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>research_object</td>
      <td>研究对象的规范化写法；比 <code>object</code> 更适合后续状态文件复用。</td>
      <td></td>
    </tr>
    <tr>
      <td>operation_type</td>
      <td>这次研究主要动作；例如解释、比较、验证、诊断、选型、规划、写作。</td>
      <td></td>
    </tr>
  </tbody>
</table>

## scope_boundary

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 58%;">
    <col style="width: 20%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">field</th>
      <th align="left">填写说明</th>
      <th align="left">填写</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>in_scope</td>
      <td>本 run 明确要覆盖的范围。</td>
      <td></td>
    </tr>
    <tr>
      <td>out_of_scope</td>
      <td>本 run 明确不覆盖的范围。</td>
      <td></td>
    </tr>
    <tr>
      <td>action_boundary</td>
      <td>本 run 允许做到什么动作；例如只读研究、写 run 内文档、改 SOP、改代码、投递 wiki。</td>
      <td></td>
    </tr>
    <tr>
      <td>user_only_decisions</td>
      <td>只能由用户决定的事项；不要把用户偏好伪装成可搜索问题。</td>
      <td></td>
    </tr>
  </tbody>
</table>

## output_action_contract

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 58%;">
    <col style="width: 20%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">field</th>
      <th align="left">填写说明</th>
      <th align="left">填写</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>product_shape</td>
      <td>预期产物形态；例如 memo、checklist、comparison table、workflow、draft。</td>
      <td></td>
    </tr>
    <tr>
      <td>audience</td>
      <td>产物给谁看、谁会使用。</td>
      <td></td>
    </tr>
    <tr>
      <td>allowed_actions</td>
      <td>本 run 明确允许执行的动作。</td>
      <td></td>
    </tr>
    <tr>
      <td>disallowed_actions</td>
      <td>本 run 明确禁止执行的动作。</td>
      <td></td>
    </tr>
    <tr>
      <td>needs_user_confirmation</td>
      <td>哪些动作或边界变化必须先问用户。</td>
      <td></td>
    </tr>
  </tbody>
</table>

## derived.use_intent

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 58%;">
    <col style="width: 20%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">field</th>
      <th align="left">填写说明</th>
      <th align="left">填写</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>value</td>
      <td>对 <code>intent</code> 的规范化表达；说明用户拿研究结果做什么。</td>
      <td></td>
    </tr>
    <tr>
      <td>derived_from</td>
      <td>这个判断来自哪些输入；例如 <code>origin_context.raw_input</code>、opening review feedback。</td>
      <td></td>
    </tr>
    <tr>
      <td>notes</td>
      <td>如果是推断、默认假设或临时判断，在这里说明。</td>
      <td></td>
    </tr>
  </tbody>
</table>

## derived.objective

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 58%;">
    <col style="width: 20%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">field</th>
      <th align="left">填写说明</th>
      <th align="left">填写</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>decision_or_action</td>
      <td>这次研究最终要支持的决策、动作或后续推进。</td>
      <td></td>
    </tr>
    <tr>
      <td>research_question</td>
      <td>为了支持上面的决策或动作，本 run 需要回答的问题。</td>
      <td></td>
    </tr>
    <tr>
      <td>current_formulation</td>
      <td>当前工作表述；后续如果问题被重构，改这里，不改原话。</td>
      <td></td>
    </tr>
  </tbody>
</table>

## derived.search_plan

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 58%;">
    <col style="width: 20%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">field</th>
      <th align="left">填写说明</th>
      <th align="left">填写</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>source_surfaces</td>
      <td>第一轮预计要打开的来源面；这是计划，不是证据回看。</td>
      <td></td>
    </tr>
  </tbody>
</table>

### derived.search_plan.first_round

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 58%;">
    <col style="width: 20%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">field</th>
      <th align="left">填写说明</th>
      <th align="left">填写</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>status</td>
      <td>首轮计划状态；例如 draft、user_confirmed、sealed。</td>
      <td></td>
    </tr>
  </tbody>
</table>

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 18%;">
    <col style="width: 28%;">
    <col style="width: 22%;">
    <col style="width: 20%;">
    <col style="width: 12%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">question</th>
      <th align="left">填写说明</th>
      <th align="left">helps_objective</th>
      <th align="left">expected_source_surfaces</th>
      <th align="left">stop_when</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td></td>
      <td>首轮自然语言研究问题，不写裸 query。</td>
      <td>这个问题如何服务 <code>research_question</code>。</td>
      <td>预计需要哪些来源面。</td>
      <td>第一轮搜到什么程度可以停。</td>
    </tr>
  </tbody>
</table>

### derived.search_plan.first_round.user_review

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 58%;">
    <col style="width: 20%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">field</th>
      <th align="left">填写说明</th>
      <th align="left">填写</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>decision</td>
      <td>用户对 opening note / first round plan 的决定；例如 pending、confirmed、revised。</td>
      <td></td>
    </tr>
    <tr>
      <td>user_feedback</td>
      <td>用户对理解、范围、产物或首轮计划的修正。</td>
      <td></td>
    </tr>
    <tr>
      <td>reviewed_at</td>
      <td>用户审阅时间；没有审阅则留空。</td>
      <td></td>
    </tr>
  </tbody>
</table>

## derived.remaining_gaps

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 58%;">
    <col style="width: 20%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">field</th>
      <th align="left">填写说明</th>
      <th align="left">填写</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>searchable</td>
      <td>opening 阶段已经识别、适合进入首轮或后续搜索的问题。</td>
      <td></td>
    </tr>
    <tr>
      <td>user_only</td>
      <td>opening 阶段必须问用户的问题。</td>
      <td></td>
    </tr>
    <tr>
      <td>deferred</td>
      <td>opening 阶段暂不处理的问题。</td>
      <td></td>
    </tr>
  </tbody>
</table>

## tracked_facets

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 15%;">
    <col style="width: 25%;">
    <col style="width: 10%;">
    <col style="width: 12%;">
    <col style="width: 10%;">
    <col style="width: 10%;">
    <col style="width: 10%;">
    <col style="width: 8%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">facet</th>
      <th align="left">填写说明</th>
      <th align="left">value</th>
      <th align="left">resolution_state</th>
      <th align="left">basis</th>
      <th align="left">alternatives</th>
      <th align="left">next_action</th>
      <th align="left">update_reason</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>use_intent</td>
      <td>跟踪用户使用意图是否稳定；只在它会影响 scope、产物或动作边界时填写。</td>
      <td></td>
      <td></td>
      <td></td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>scope_boundary</td>
      <td>跟踪范围边界是否稳定；只在边界会影响首轮检索或输出动作时填写。</td>
      <td></td>
      <td></td>
      <td></td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>output_action_contract</td>
      <td>跟踪产物形态和动作边界是否稳定。</td>
      <td></td>
      <td></td>
      <td></td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
  </tbody>
</table>

## change_log

<table style="width: 100%; table-layout: fixed;">
  <colgroup>
    <col style="width: 22%;">
    <col style="width: 22%;">
    <col style="width: 34%;">
    <col style="width: 22%;">
  </colgroup>
  <thead>
    <tr>
      <th align="left">time</th>
      <th align="left">source</th>
      <th align="left">change</th>
      <th align="left">reason</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td></td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
  </tbody>
</table>
