<ul>
  <li><a href="@acs_admin_url@cache">Cache Info</a>
  <if @acs_automated_testing_url@ not nil>
    <li><a href="@acs_automated_testing_url@admin">Automated Testing</a>
  </if>
  <if @acs_service_contract_url@ not nil>
    <li><a href="@acs_service_contract_url@">Service Contracts</a>
  </if>
  <li><a href="@acs_api_browser_url@">API Browser</a>
</ul>
<p>
