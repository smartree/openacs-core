<master>
  <property name="title">@page_title@</property>

<h3>Core Services</h3>

<include src="/packages/acs-admin/lib/site-wide-services">

<if @packages:rowcount@ gt 0>
  <h3>Site-Wide Package Administration</h3>
  <ul>
    <multiple name="packages">
      <li><a href="@packages.admin_url@/\">@packages.pretty_name@</a></li>
    </multiple>
  </ul>
</if>

<if @subsites:rowcount@ gt 0>
  <h3>Subsite Administration</h3>
  <ul>
    <multiple name="subsites">
      <li><a href="@subsites.admin_url@">@subsites.instance_name@ Administration</a></li>
    </multiple>
  </ul>
</if>

<h3>Package Parameters</h3>

<include src="/packages/acs-admin/lib/service-parameters">


