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
      <td>action_in_scope</td>
      <td>本 run 明确允许执行的动作；例如只读研究、写 run 内文档、改 SOP、投递 wiki。</td>
      <td></td>
    </tr>
    <tr>
      <td>action_out_of_scope</td>
      <td>本 run 明确不允许执行的动作；例如不改代码、不写 wiki 正文、不登录账号、不调用付费 API。</td>
      <td></td>
    </tr>
  </tbody>
</table>

## output_contract

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
  </tbody>
</table>

## derived.research_goal

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
      <td>research_goal</td>
      <td>从 <code>origin_context.raw_input</code>、<code>inquiry_shape.research_object</code>、<code>inquiry_shape.operation_type</code> 衍生；说明用户为什么要做这次研究、研究对象是什么、准备用结果支持什么判断、决策或后续工作。可以写 1-3 句，不强行压成一句；不要把未确认偏好写成事实。</td>
      <td></td>
    </tr>
  </tbody>
</table>

## derived.boundary

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
      <td>boundary</td>
      <td>从 <code>scope_boundary.in_scope</code>、<code>scope_boundary.out_of_scope</code>、<code>scope_boundary.action_in_scope</code>、<code>scope_boundary.action_out_of_scope</code>、<code>output_contract.product_shape</code>、<code>output_contract.audience</code> 衍生；总结本 run 的内容边界、动作边界、产物形态和目标读者，用来约束后续 <code>search_plan</code>。</td>
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
      <td>questions</td>
      <td>从 <code>derived.research_goal</code> 和 <code>derived.boundary</code> 衍生；写首轮自然语言研究问题，说明第一轮要先验证什么、为什么这些问题足以启动研究。不写裸 query；具体 query 生成和工具调用后续另行讨论。</td>
      <td></td>
    </tr>
    <tr>
      <td>source_surfaces</td>
      <td>从 <code>derived.research_goal</code>、<code>derived.boundary</code> 和 <code>questions</code> 衍生；只能从 <code>primary</code>、<code>community</code>、<code>web</code> 中选择并说明理由。<code>primary</code> 指研究对象本身或直接责任方的一手来源，例如官方 docs、repo、release notes、产品公告、政府文件、论文原文。<code>community</code> 指围绕问题有持续讨论、经验交换或问题复现的社区入口，例如 GitHub issues/discussions、Reddit、V2EX、知乎、小红书、专业论坛；单条新闻、公告、转发或孤立社媒内容不算 community。<code>web</code> 指普通网页和二手整理，例如博客、媒体报道、教程、评测、资料汇总。</td>
      <td></td>
    </tr>
    <tr>
      <td>stop_when</td>
      <td>从 <code>questions</code> 和 <code>source_surfaces</code> 衍生；写第一轮可以停止的证据条件，例如 primary 来源已确认规则或事实、community 已出现稳定重复的问题模式、web 来源只剩重复转述、或者关键冲突已经暴露到足以进入下一轮判断。它用于限制第一轮搜索不要无限展开，也用于之后判断是否需要补搜。</td>
      <td></td>
    </tr>
  </tbody>
</table>
