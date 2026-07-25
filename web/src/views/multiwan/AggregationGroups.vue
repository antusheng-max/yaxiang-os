<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>双栈线路汇聚</h2>
      <p>将多条宽带组成统一出口，并分别管理传统互联网协议（IPv4）与新一代互联网协议（IPv6）的线路选择方式。</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <CardToolbar class="toolbar">
            <el-button type="primary" @click="openCreate">+ 新建双栈汇聚</el-button>
            <el-button @click="loadData">刷新</el-button>
          </CardToolbar>

          <el-alert
            class="mode-alert"
            type="info"
            :closable="false"
            show-icon
            title="本页面仅展示前端演示数据。统一前缀转换（NPTv6）和IPv6地址转换（NAT66）均不会生成真实网络规则。"
          />
      
          <div v-loading="loading" class="group-list">
            <SectionCard
              v-for="g in list"
              :key="g.id"
              shadow="never"
              class="group-card"
            >
              <div class="group-head">
                <div class="group-title">
                  <h3>{{ g.name }}</h3>
                  <el-tag v-if="g.enabled" type="success" size="small">启用</el-tag>
                  <el-tag v-else type="info" size="small">已禁用</el-tag>
                </div>
                <div class="group-actions">
                  <el-button link type="primary" @click="openEdit(g)">编辑</el-button>
                  <el-button link type="danger" @click="removeItem(g)">删除</el-button>
                </div>
              </div>
              <p v-if="g.description" class="group-desc">{{ g.description }}</p>
      
              <el-row :gutter="16" class="group-section">
                <el-col :xs="24" :lg="14">
                  <CardContent padding="none">
                    <div class="section-title">成员线路</div>
                    <StandardTable layout-mode="fill" :data="getMembers(g)" size="default" border>
                      <el-table-column prop="name" label="线路名称" min-width="125" />
                      <el-table-column prop="carrier" label="运营商" min-width="95" />
                      <el-table-column label="IPv6能力状态" min-width="255">
                        <template #header>
                          <span class="table-header-help">
                            IPv6能力状态
                            <el-tooltip content="每条线路独立检测公网IPv6地址、运营商前缀、兼容出站和中继能力。没有PD不会直接影响IPv4调度。">
                              <el-icon><QuestionFilled /></el-icon>
                            </el-tooltip>
                          </span>
                        </template>
                        <template #default="{ row }">
                          <div class="capability-cell">
                            <div class="capability-heading">
                              <el-tag :type="row.ipv6Capability.tagType" size="small">
                                {{ row.ipv6Capability.label }}
                              </el-tag>
                              <span>{{ row.ipv6Capability.eligibilityLabel }}</span>
                            </div>
                            <small>{{ row.ipv6Capability.explanation }}</small>
                          </div>
                        </template>
                      </el-table-column>
                      <el-table-column prop="connections" label="连接数" min-width="80" />
                    </StandardTable>
                  </CardContent>
                </el-col>
                <el-col :xs="24" :lg="10">
                 <div class="section-title">绑定与策略</div>
                 <el-descriptions :column="1" size="small" border>
                    <el-descriptions-item label="绑定局域网">{{ getLanName(g.lanNetworkId) }}</el-descriptions-item>
                    <el-descriptions-item label="局域网端口">{{ getPortName(g.lanPhysicalPortId) }}</el-descriptions-item>
                    <el-descriptions-item label="调度策略">{{ getPolicyName(g.schedulingPolicyId) }}</el-descriptions-item>
                    <el-descriptions-item label="健康检测策略">{{ getHealthPolicyName(g.healthCheckPolicyId) }}</el-descriptions-item>
                  </el-descriptions>
                </el-col>
              </el-row>
      
              <el-row :gutter="16" class="group-section">
                <el-col :span="12">
                  <div class="section-title">IPv4 设置摘要</div>
                  <el-descriptions :column="1" size="small" border>
                    <el-descriptions-item label="启用">
                      <el-tag :type="g.ipv4Settings?.enabled ? 'success' : 'info'" size="small">
                        {{ g.ipv4Settings?.enabled ? '是' : '否' }}
                      </el-tag>
                    </el-descriptions-item>
                    <el-descriptions-item label="工作模式">{{ ipv4ModeText(g.ipv4Settings?.mode) }}</el-descriptions-item>
                    <el-descriptions-item label="调度模式">{{ scheduleModeText(g.ipv4Settings?.scheduleMode) }}</el-descriptions-item>
                    <el-descriptions-item label="会话保持">{{ g.ipv4Settings?.sessionPersistence ? '开启' : '关闭' }}</el-descriptions-item>
                  </el-descriptions>
                </el-col>
                <el-col :span="12">
                  <div class="section-title">IPv6 设置摘要</div>
                  <el-descriptions :column="1" size="small" border>
                    <el-descriptions-item label="启用">
                      <el-tag :type="g.ipv6Settings?.enabled ? 'success' : 'info'" size="small">
                        {{ g.ipv6Settings?.enabled ? '是' : '否' }}
                      </el-tag>
                    </el-descriptions-item>
                    <el-descriptions-item label="IPv6 出口模式">{{ ipv6ModeText(g.ipv6Settings?.mode) }}</el-descriptions-item>
                    <el-descriptions-item label="模式说明">{{ ipv6ModeDescription(g.ipv6Settings?.mode) }}</el-descriptions-item>
                    <el-descriptions-item label="未获得IPv6前缀时">
                      {{ noPdHandlingText(g.ipv6Settings?.noPdLineHandling) }}
                    </el-descriptions-item>
                    <el-descriptions-item label="IPv6 DNS处理方式">
                      {{ ipv6DnsHandlingText(g.ipv6Settings?.ipv6DnsStrategy) }}
                    </el-descriptions-item>
                    <el-descriptions-item label="局域网稳定前缀">
                      {{ g.ipv6Settings?.lanInternalPrefix || '—' }}
                    </el-descriptions-item>
                  </el-descriptions>
                </el-col>
              </el-row>
      
              <div class="group-section">
                <div class="section-title">拓扑视图</div>
                <pre class="topo">{{ topology(g) }}</pre>
              </div>
      
              <div class="group-section">
                <div class="section-title">运行时统计</div>
                <el-row :gutter="8">
                  <el-col :span="4"><div class="rt-stat"><div class="rt-label">IPv4 在线</div><div class="rt-value">{{ g.runtimeStatus?.ipv4OnlineMembers || 0 }}/{{ g.memberDialInstanceIds?.length || 0 }}</div></div></el-col>
                  <el-col :span="4"><div class="rt-stat"><div class="rt-label">IPv6 在线</div><div class="rt-value">{{ g.runtimeStatus?.ipv6OnlineMembers || 0 }}/{{ g.memberDialInstanceIds?.length || 0 }}</div></div></el-col>
                  <el-col :span="4"><div class="rt-stat"><div class="rt-label">获得运营商前缀（PD）</div><div class="rt-value">{{ g.runtimeStatus?.membersWithPd || 0 }}/{{ g.memberDialInstanceIds?.length || 0 }}</div></div></el-col>
                  <el-col :span="4"><div class="rt-stat"><div class="rt-label">统一前缀转换</div><div class="rt-value">{{ g.runtimeStatus?.nptv6Count || 0 }} 条</div></div></el-col>
                  <el-col :span="4"><div class="rt-stat"><div class="rt-label">兼容地址转换</div><div class="rt-value">{{ g.runtimeStatus?.nat66FallbackCount || 0 }} 条</div></div></el-col>
                  <el-col :span="4"><div class="rt-stat"><div class="rt-label">当前连接数</div><div class="rt-value">{{ (g.runtimeStatus?.currentIpv4Connections || 0) + (g.runtimeStatus?.currentIpv6Connections || 0) }}</div></div></el-col>
                </el-row>
                <div class="rt-total">总下行 {{ g.runtimeStatus?.totalRxMbps || 0 }} 兆比特/秒 / 总上行 {{ g.runtimeStatus?.totalTxMbps || 0 }} 兆比特/秒</div>
              </div>
            </SectionCard>
          </div>
      
          <StandardModal size="standard"
            v-model="dialogVisible"
            :title="isEdit ? '编辑双栈汇聚' : '新建双栈汇聚'"
          >
            <el-form :model="form" label-width="160px">
              <el-divider content-position="left">基础信息</el-divider>
              <el-form-item label="名称" required>
                <el-input v-model="form.name" />
              </el-form-item>
              <el-form-item label="描述">
                <el-input v-model="form.description" type="textarea" :rows="2" />
              </el-form-item>
              <el-form-item label="启用">
                <el-switch v-model="form.enabled" />
              </el-form-item>
              <el-form-item label="成员线路" required>
                <el-select v-model="form.memberDialInstanceIds" multiple placeholder="选择线路">
                  <el-option v-for="d in dialInstances" :key="d.id" :label="d.name" :value="d.id" />
                </el-select>
              </el-form-item>
              <el-form-item label="绑定局域网">
                <el-select v-model="form.lanNetworkId" clearable placeholder="选择局域网">
                  <el-option v-for="lan in lans" :key="lan.id" :label="lan.name" :value="lan.id" />
                </el-select>
                <div class="form-hint">局域网（LAN）是服务器和终端所在的内部网络。</div>
              </el-form-item>
              <el-form-item label="局域网物理端口">
                <el-select v-model="form.lanPhysicalPortId" clearable placeholder="选择物理端口">
                  <el-option v-for="port in physicalPorts" :key="port.id" :label="port.name" :value="port.id" />
                </el-select>
              </el-form-item>
              <el-form-item label="调度策略">
                <el-select v-model="form.schedulingPolicyId" clearable>
                  <el-option v-for="p in policies" :key="p.id" :label="p.name" :value="p.id" />
                </el-select>
                <div class="form-hint">决定新连接在多条线路之间如何分配。</div>
              </el-form-item>
              <el-form-item label="健康检测策略">
                <el-select v-model="form.healthCheckPolicyId" clearable>
                  <el-option v-for="p in healthPolicies" :key="p.id" :label="p.name" :value="p.id" />
                </el-select>
                <div class="form-hint">IPv4和IPv6分别检测、分别摘除，并在恢复后分别重新加入。</div>
              </el-form-item>
      
              <el-divider content-position="left">IPv4 汇聚设置</el-divider>
              <el-form-item label="启用 IPv4 汇聚">
                <el-switch v-model="form.ipv4Settings.enabled" />
              </el-form-item>
              <el-form-item label="工作模式">
                <el-input :model-value="ipv4ModeText(form.ipv4Settings.mode)" disabled />
                <div class="form-hint">为IPv4新连接选择出口并使用对应线路地址访问互联网。</div>
              </el-form-item>
              <el-form-item>
                <template #label>
                  <span class="field-label">
                    调度模式
                    <el-tooltip :content="scheduleModeDescription(form.ipv4Settings.scheduleMode)">
                      <el-icon><QuestionFilled /></el-icon>
                    </el-tooltip>
                  </span>
                </template>
                <el-select v-model="form.ipv4Settings.scheduleMode">
                  <el-option label="平均连接" value="round_robin" />
                  <el-option label="加权连接" value="weighted" />
                  <el-option label="最少连接加权" value="least_conn_weighted" />
                  <el-option label="按剩余带宽" value="bandwidth_aware" />
                  <el-option label="源地址固定" value="source_hash" />
                  <el-option label="目标地址固定" value="destination_hash" />
                </el-select>
                <div class="form-hint">{{ scheduleModeDescription(form.ipv4Settings.scheduleMode) }}</div>
              </el-form-item>
              <el-form-item label="会话保持">
                <el-switch v-model="form.ipv4Settings.sessionPersistence" />
              </el-form-item>
              <el-form-item label="回程保持">
                <el-switch v-model="form.ipv4Settings.returnPathKeep" />
              </el-form-item>
              <el-form-item label="故障摘除">
                <el-switch v-model="form.ipv4Settings.autoRemoveFailed" />
              </el-form-item>
              <el-form-item label="恢复加入">
                <el-switch v-model="form.ipv4Settings.autoRejoin" />
              </el-form-item>
              <el-form-item>
                <template #label>
                  <span class="field-label">
                    可靠连接分配方式
                    <el-tooltip content="TCP是面向连接的传输控制协议，常用于网页、文件传输和数据库连接。">
                      <el-icon><QuestionFilled /></el-icon>
                    </el-tooltip>
                  </span>
                </template>
                <el-select v-model="form.ipv4Settings.tcpSessionPolicy">
                  <el-option
                    v-for="option in sessionPolicyOptions"
                    :key="option.value"
                    :label="option.label"
                    :value="option.value"
                  />
                </el-select>
                <div class="form-hint">用于网页、文件和数据库等可靠连接，内部策略标识不会显示给普通用户。</div>
              </el-form-item>
              <el-form-item>
                <template #label>
                  <span class="field-label">
                    实时数据分配方式
                    <el-tooltip content="UDP是无连接的数据报协议，常用于语音、视频、游戏和域名解析。">
                      <el-icon><QuestionFilled /></el-icon>
                    </el-tooltip>
                  </span>
                </template>
                <el-select v-model="form.ipv4Settings.udpSessionPolicy">
                  <el-option
                    v-for="option in sessionPolicyOptions"
                    :key="option.value"
                    :label="option.label"
                    :value="option.value"
                  />
                </el-select>
                <div class="form-hint">用于语音、视频和域名解析等实时数据，内部策略标识不会显示给普通用户。</div>
              </el-form-item>
              <el-form-item label="排除管理流量">
                <el-switch v-model="form.ipv4Settings.excludeMgmtTraffic" />
              </el-form-item>
              <el-form-item v-if="form.ipv4Settings.excludeMgmtTraffic" label="自定义排除网段">
                <el-input v-model="form.ipv4Settings.customExcludedTargets" placeholder="例如：192.168.0.0/16，多个网段用逗号分隔" />
                <div class="form-hint">填写不参与线路汇聚的内部IP地址范围。</div>
              </el-form-item>
              <el-alert
                type="info"
                :closable="false"
                show-icon
                title="线路汇聚按连接分配出口。不同连接可以使用不同宽带，但单个已经建立的连接不会被拆分到多条外网线路。"
      
              />
      
              <el-divider content-position="left">IPv6 汇聚设置</el-divider>
              <el-form-item label="启用 IPv6 汇聚">
                <el-switch v-model="form.ipv6Settings.enabled" />
              </el-form-item>
              <el-form-item>
                <template #label>
                  <span class="field-label">
                    IPv6出口模式
                    <el-tooltip content="决定局域网IPv6地址如何与多条运营商线路配合。本阶段仅保存前端演示数据。">
                      <el-icon><QuestionFilled /></el-icon>
                    </el-tooltip>
                  </span>
                </template>
                <el-radio-group
                  v-model="form.ipv6Settings.mode"
                  class="ipv6-mode-options"
                  @change="onIpv6ModeChange"
                >
                  <el-radio value="stable_prefix" border>
                    <span class="mode-title">
                      统一局域网前缀
                      <el-tag type="success" size="small">推荐</el-tag>
                      <el-tooltip content="内部前缀保持稳定，系统根据出口映射到对应运营商前缀。前缀转换功能本阶段不会下发真实规则。">
                        <el-icon><QuestionFilled /></el-icon>
                      </el-tooltip>
                    </span>
                    <span class="mode-description">
                      局域网使用一个稳定内部IPv6前缀，系统根据所选外网线路映射为对应运营商IPv6前缀。
                    </span>
                  </el-radio>
                  <el-radio value="native_multi_prefix" border>
                    <span class="mode-title">
                      原生多前缀
                      <el-tag type="warning" size="small">高级</el-tag>
                      <el-tooltip content="向同一局域网发布多个运营商前缀，并保持源IPv6地址与所选出口一致。">
                        <el-icon><QuestionFilled /></el-icon>
                      </el-tooltip>
                    </span>
                    <span class="mode-description">
                      将每条外网线路的IPv6前缀下发到同一个局域网，调度时选择对应源IPv6地址和出口。
                    </span>
                  </el-radio>
                  <el-radio value="nat66_compat" border>
                    <span class="mode-title">
                      NAT66兼容模式
                      <el-tag type="warning" size="small">高级</el-tag>
                      <el-tooltip content="NAT66是IPv6地址转换，仅用于缺少可用运营商前缀的兼容场景，不等同于原生公网前缀。">
                        <el-icon><QuestionFilled /></el-icon>
                      </el-tooltip>
                    </span>
                    <span class="mode-description">
                      仅用于运营商不提供可用前缀委派（PD）或前缀条件不满足时。
                    </span>
                  </el-radio>
                </el-radio-group>
                <div class="form-hint">IPv6是新一代互联网协议；三种模式只影响IPv6，不改变IPv4线路调度。</div>
              </el-form-item>
              <el-form-item
                v-if="form.ipv6Settings.mode === 'stable_prefix'"
                label="局域网内部前缀"
              >
                <el-input v-model="form.ipv6Settings.lanInternalPrefix" placeholder="如 fd00::/64" />
                <div class="form-hint">供局域网设备和服务器长期使用的稳定内部IPv6地址范围。</div>
              </el-form-item>
              <el-form-item
                v-if="form.ipv6Settings.mode === 'stable_prefix'"
                label="局域网网关"
              >
                <el-input v-model="form.ipv6Settings.lanGateway" placeholder="如 fd00::1" />
                <div class="form-hint">局域网设备访问IPv6网络时使用的默认出口地址。</div>
              </el-form-item>
              <el-form-item
                v-if="form.ipv6Settings.mode === 'native_multi_prefix'"
                label="源地址与出口保持一致"
              >
                <el-switch v-model="form.ipv6Settings.sourceAddressBinding" />
              </el-form-item>
              <el-alert
                v-if="form.ipv6Settings.mode === 'nat66_compat'"
                type="warning"
                :closable="false"
                title="高级兼容模式仅作为前缀条件不足时的备选方案，本阶段不会生成真实IPv6地址转换规则。"
              />
              <el-form-item label="会话保持">
                <el-switch v-model="form.ipv6Settings.ipv6SessionPersistence" />
              </el-form-item>
              <el-form-item label="回程保持">
                <el-switch v-model="form.ipv6Settings.ipv6ReturnPathKeep" />
              </el-form-item>
              <el-form-item label="运营商前缀变化后重建">
                <el-switch v-model="form.ipv6Settings.autoRebuildOnPrefixChange" />
                <div class="form-hint">运营商重新分配IPv6前缀后，自动刷新前端演示中的线路映射状态。</div>
              </el-form-item>
              <el-form-item>
                <template #label>
                  <span class="field-label">
                    未获得IPv6前缀时
                    <el-tooltip content="IPv6-PD即IPv6前缀委派。获得PD后，系统可以从运营商前缀中为LAN分配IPv6子网。">
                      <el-icon class="help-icon"><QuestionFilled /></el-icon>
                    </el-tooltip>
                  </span>
                </template>
                <el-select v-model="form.ipv6Settings.noPdLineHandling">
                  <el-option
                    v-for="option in noPdHandlingOptions"
                    :key="option.value"
                    :label="option.badge ? `${option.label}（${option.badge}）` : option.label"
                    :value="option.value"
                  >
                    <span>{{ option.label }}</span>
                    <el-tag
                      v-if="option.badge"
                      :type="option.risk === 'recommended' ? 'success' : 'warning'"
                      size="small"
                    >
                      {{ option.badge }}
                    </el-tag>
                  </el-option>
                </el-select>
                <div class="form-hint">
                  PD是运营商分配给路由器、供LAN和服务器使用的IPv6公网前缀。没有PD不一定表示该线路完全没有IPv6。
                </div>
                <div class="selection-description">{{ selectedNoPdOption.description }}</div>
                <ul class="selection-detail-list">
                  <li v-for="detail in selectedNoPdOption.detail" :key="detail">{{ detail }}</li>
                </ul>
                <div class="handling-impact-grid">
                  <div><span>参与IPv6调度</span><strong>{{ selectedNoPdOption.scheduling }}</strong></div>
                  <div><span>IPv6出站</span><strong>{{ selectedNoPdOption.outbound }}</strong></div>
                  <div><span>服务器入站</span><strong>{{ selectedNoPdOption.inbound }}</strong></div>
                  <div><span>是否需要PD</span><strong>{{ selectedNoPdOption.requiresPd }}</strong></div>
                  <div><span>地址转换</span><strong>{{ selectedNoPdOption.translation }}</strong></div>
                  <div><span>对IPv4影响</span><strong>{{ selectedNoPdOption.ipv4Impact }}</strong></div>
                </div>
              </el-form-item>
              <el-form-item>
                <template #label>
                  <span class="field-label">
                    IPv6 DNS处理方式
                    <el-tooltip content="DNS是域名系统，用于把网站名称转换成IPv6地址。下拉框只显示中文名称，内部策略标识不会展示给普通用户。">
                      <el-icon><QuestionFilled /></el-icon>
                    </el-tooltip>
                  </span>
                </template>
                <el-select v-model="form.ipv6Settings.ipv6DnsStrategy">
                  <el-option
                    v-for="option in ipv6DnsOptions"
                    :key="option.value"
                    :label="option.badge ? `${option.label}（${option.badge}）` : option.label"
                    :value="option.value"
                  >
                    <span>{{ option.label }}</span>
                    <el-tag
                      v-if="option.badge"
                      :type="option.badge === '推荐' ? 'success' : 'warning'"
                      size="small"
                    >
                      {{ option.badge }}
                    </el-tag>
                  </el-option>
                </el-select>
                <div class="form-hint">{{ selectedDnsOption.description }}</div>
                <div class="selection-description">{{ selectedDnsOption.detail }}</div>
              </el-form-item>
              <el-form-item
                v-if="form.ipv6Settings.ipv6DnsStrategy === 'custom'"
                label="自定义IPv6 DNS服务器"
              >
                <el-input
                  v-model="form.ipv6Settings.customIpv6DnsServers"
                  placeholder="例如：240c::6666，多个地址用逗号分隔"
                />
                <div class="form-hint">请填写可以从当前网络访问的IPv6域名服务器地址。</div>
              </el-form-item>
              <el-form-item>
                <template #label>
                  <span class="field-label">
                    局域网IPv6配置下发
                    <el-tooltip content="RA是路由器公告，用于告诉设备IPv6网络信息；DHCPv6由系统向设备分配IPv6参数。">
                      <el-icon><QuestionFilled /></el-icon>
                    </el-tooltip>
                  </span>
                </template>
                <el-select v-model="form.ipv6Settings.raMode">
                  <el-option label="自动地址公告" value="slaac" />
                  <el-option label="由系统分配地址" value="managed" />
                  <el-option label="地址公告并下发辅助参数" value="assisted" />
                </el-select>
                <div class="form-hint">{{ raModeDescription(form.ipv6Settings.raMode) }}</div>
              </el-form-item>
            </el-form>
      
            <template #footer>
              <el-button @click="dialogVisible = false">取消</el-button>
              <el-button type="primary" @click="save">保存</el-button>
            </template>
          </StandardModal>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { computed, ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  aggregationGroupService,
  dialInstanceService,
  healthCheckService,
  lanService,
  physicalPortService,
  policyService,
  runtimeStatusService,
} from '../../services/dataService.js'
import { toDialStatusRow } from '../../models/networkViewModels.js'
import {
  IPV6_DNS_HANDLING_OPTIONS,
  NO_PD_HANDLING_OPTIONS,
  getIpv6DnsHandlingOption,
  getNoPdHandlingOption,
  resolveIpv6Capability,
} from '../../models/dualStackAggregation.js'

const loading = ref(false)
const list = ref([])
const dialInstances = ref([])
const policies = ref([])
const healthPolicies = ref([])
const lans = ref([])
const physicalPorts = ref([])
const dialogVisible = ref(false)
const isEdit = ref(false)
const ipv6DnsOptions = IPV6_DNS_HANDLING_OPTIONS
const noPdHandlingOptions = NO_PD_HANDLING_OPTIONS
const sessionPolicyOptions = Object.freeze([
  { value: 'source_hash', label: '按源地址固定线路' },
  { value: 'destination_hash', label: '按目标地址固定线路' },
  { value: 'round_robin', label: '连接依次分配' },
])

const defaultForm = () => ({
  id: null,
  name: '',
  description: '',
  enabled: true,
  memberDialInstanceIds: [],
  lanNetworkId: '',
  lanPhysicalPortId: '',
  schedulingPolicyId: '',
  healthCheckPolicyId: '',
  ipv4Settings: {
    enabled: true,
    mode: 'nat_multiwan',
    scheduleMode: 'least_conn_weighted',
    sessionPersistence: true,
    returnPathKeep: true,
    autoRemoveFailed: true,
    autoRejoin: true,
    tcpSessionPolicy: 'source_hash',
    udpSessionPolicy: 'source_hash',
    excludeMgmtTraffic: true,
    customExcludedTargets: '',
  },
  ipv6Settings: {
    enabled: true,
    mode: 'stable_prefix',
    lanInternalPrefix: '',
    lanGateway: '',
    nptv6Enabled: true,
    nat66Fallback: false,
    sourceAddressBinding: true,
    ipv6SessionPersistence: true,
    ipv6ReturnPathKeep: true,
    autoRebuildOnPrefixChange: true,
    noPdLineHandling: 'auto_best',
    noPdHandlingVersion: 2,
    ipv6DnsStrategy: 'wan_follow',
    customIpv6DnsServers: '',
    raMode: 'managed',
  },
})
const form = reactive(defaultForm())
const selectedNoPdOption = computed(
  () => getNoPdHandlingOption(form.ipv6Settings.noPdLineHandling),
)
const selectedDnsOption = computed(
  () => getIpv6DnsHandlingOption(form.ipv6Settings.ipv6DnsStrategy),
)

const ipv6ModeText = (m) => ({
  stable_prefix: '统一局域网前缀（推荐）',
  native_multi_prefix: '原生多前缀',
  nat66_compat: 'NAT66兼容模式（高级）',
}[m] || '—')
const ipv6ModeDescription = (mode) => ({
  stable_prefix: '稳定内部前缀按所选出口映射到运营商前缀，IPv4仍独立调度。',
  native_multi_prefix: '多条运营商前缀同时下发，并让源IPv6地址与出口保持一致。',
  nat66_compat: '仅用于无可用运营商前缀的高级兼容场景，主要面向出站流量。',
}[mode] || '—')
const ipv4ModeText = (mode) => ({
  nat_multiwan: '多线路地址转换',
}[mode] || '—')
const scheduleModeText = (mode) => ({
  round_robin: '平均连接',
  weighted: '加权连接',
  least_conn_weighted: '最少连接加权',
  bandwidth_aware: '按剩余带宽',
  source_hash: '源地址固定',
  destination_hash: '目标地址固定',
}[mode] || '—')
const scheduleModeDescription = (mode) => ({
  round_robin: '新连接按线路顺序依次分配，适合能力相近的宽带。',
  weighted: '按设定权重分配新连接，权重越高，获得新连接的概率越大。',
  least_conn_weighted: '综合当前连接数和线路权重，优先选择负载较轻的线路。',
  bandwidth_aware: '根据剩余上行能力动态分配新连接。',
  source_hash: '同一来源地址的新连接尽量保持在同一条线路。',
  destination_hash: '访问同一目标地址的新连接尽量保持在同一条线路。',
}[mode] || '选择新连接在多条IPv4线路之间的分配方式。')
const raModeDescription = (mode) => ({
  slaac: '路由器发布IPv6网络信息，设备自行生成地址。',
  managed: '由系统统一向局域网设备分配IPv6地址和参数。',
  assisted: '设备自行生成地址，系统同时下发域名服务器等辅助参数。',
}[mode] || '选择局域网设备获得IPv6地址和参数的方式。')
const noPdHandlingText = value => {
  const option = getNoPdHandlingOption(value)
  return option.badge ? `${option.label}（${option.badge}）` : option.label
}
const ipv6DnsHandlingText = value => {
  const option = getIpv6DnsHandlingOption(value)
  return option.badge ? `${option.label}（${option.badge}）` : option.label
}
const getLanName = id => lans.value.find(item => item.id === id)?.name || '—'
const getPortName = id => physicalPorts.value.find(item => item.id === id)?.name || '—'
const getPolicyName = id => policies.value.find(item => item.id === id)?.name || '—'
const getHealthPolicyName = id => healthPolicies.value.find(item => item.id === id)?.name || '—'

function getMembers(g) {
  if (!g.memberDialInstanceIds) return []
  return dialInstances.value
    .filter(d => g.memberDialInstanceIds.includes(d.id))
    .map(line => ({
      ...line,
      ipv6Capability: resolveIpv6Capability(
        line,
        g.ipv6Settings?.noPdLineHandling,
      ),
    }))
}

function topology(g) {
  const members = getMembers(g)
  const lines = members.map(m => `${m.name} ─┐`).join('\n')
  return `${lines}
         ├─ ${g.name} ─ ${getLanName(g.lanNetworkId)} ─ ${getPortName(g.lanPhysicalPortId)} ─ 下游服务器`
}

async function loadData() {
  loading.value = true
  try {
    const [g, d, p, h, lanItems, portItems] = await Promise.all([
      aggregationGroupService.list(),
      dialInstanceService.list(),
      policyService.list(),
      healthCheckService.list(),
      lanService.list(),
      physicalPortService.list(),
    ])
    list.value = g.map(group => ({
      ...group,
      runtimeStatus: runtimeStatusService.getGroupStatus(group.id) || group.runtimeStatus,
    }))
    dialInstances.value = d.map(toDialStatusRow)
    policies.value = p
    healthPolicies.value = h
    lans.value = lanItems
    physicalPorts.value = portItems
  } catch (e) {
    ElMessage.error('加载失败：' + e.message)
  } finally {
    loading.value = false
  }
}

function openCreate() {
  Object.assign(form, defaultForm())
  isEdit.value = false
  dialogVisible.value = true
}
function openEdit(g) {
  Object.assign(form, defaultForm(), JSON.parse(JSON.stringify(g)))
  isEdit.value = true
  dialogVisible.value = true
}

function onIpv6ModeChange(mode) {
  form.ipv6Settings.nptv6Enabled = mode === 'stable_prefix'
  form.ipv6Settings.nat66Fallback = mode === 'nat66_compat'
  form.ipv6Settings.sourceAddressBinding = mode === 'native_multi_prefix'
}

async function save() {
  if (!form.name || !form.memberDialInstanceIds?.length) {
    ElMessage.warning('请填写名称和成员')
    return
  }
  const payload = JSON.parse(JSON.stringify({
    id: form.id,
    name: form.name,
    description: form.description,
    enabled: form.enabled,
    memberDialInstanceIds: form.memberDialInstanceIds,
    lanNetworkId: form.lanNetworkId,
    lanPhysicalPortId: form.lanPhysicalPortId,
    schedulingPolicyId: form.schedulingPolicyId,
    healthCheckPolicyId: form.healthCheckPolicyId,
    ipv4Settings: form.ipv4Settings,
    ipv6Settings: form.ipv6Settings,
  }))
  try {
    if (isEdit.value) {
      await aggregationGroupService.update(form.id, payload)
      ElMessage.success('已保存')
    } else {
      await aggregationGroupService.create(payload)
      ElMessage.success('已创建')
    }
    dialogVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error('保存失败：' + e.message)
  }
}

async function removeItem(g) {
  try {
    await aggregationGroupService.remove(g.id)
    ElMessage.success('已删除 ' + g.name)
    loadData()
  } catch (e) {
    ElMessage.error('删除失败：' + e.message)
  }
}

onMounted(loadData)
</script>

<style scoped>
.group-list { display: flex; flex-direction: column; gap: 16px; }
.mode-alert { margin-bottom: 16px; }
.group-card { border-radius: 4px; }
.group-head { display: flex; justify-content: space-between; align-items: center; }
.group-title { display: flex; align-items: center; gap: 8px; }
.group-title h3 { margin: 0; font-size: 18px; }
.group-desc { color: #666; font-size: 14px; margin: 6px 0 0 0; }
.group-section { margin-top: 16px; }
.section-title { font-size: 14px; font-weight: 600; margin-bottom: 8px; color: #303133; }
.topo { background: #f5f7fa; padding: 12px; font-family: monospace; font-size: 13px; border-radius: 4px; white-space: pre; overflow-x: auto; margin: 0; }
.rt-stat { background: #f5f7fa; padding: 8px; border-radius: 4px; text-align: center; }
.rt-label { font-size: 12px; color: #666; }
.rt-value { font-size: 14px; font-weight: 600; margin-top: 4px; }
.rt-total { margin-top: 8px; font-size: 13px; color: #606266; }
:deep(.el-table) { font-size: 14px; }
:deep(.el-table td) { padding: 8px 0; }
:deep(.el-divider__text) { font-size: 14px; font-weight: 600; }
.field-label,
.table-header-help,
.mode-title,
.capability-heading {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.field-label :deep(.el-icon),
.table-header-help :deep(.el-icon),
.mode-title :deep(.el-icon) {
  color: var(--lh-primary);
  cursor: help;
}
.form-hint,
.selection-description {
  width: 100%;
  margin-top: 5px;
  color: var(--lh-text-secondary);
  font-size: 12px;
  line-height: 20px;
}
.selection-description {
  padding: 8px 10px;
  border-radius: 4px;
  background: var(--el-fill-color-lighter);
  color: var(--lh-text);
}
.selection-detail-list {
  width: 100%;
  margin: 6px 0 0;
  padding-left: 20px;
  color: var(--lh-text-secondary);
  font-size: 12px;
  line-height: 21px;
}
.handling-impact-grid {
  display: grid;
  width: 100%;
  margin-top: 8px;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
}
.handling-impact-grid > div {
  display: flex;
  min-width: 0;
  justify-content: space-between;
  gap: 10px;
  padding: 8px 10px;
  border: 1px solid var(--el-border-color-lighter);
  border-radius: 4px;
  background: var(--el-bg-color);
  font-size: 12px;
}
.handling-impact-grid span {
  color: var(--lh-text-secondary);
}
.handling-impact-grid strong {
  text-align: right;
}
.capability-cell {
  min-width: 0;
  line-height: 18px;
}
.capability-heading {
  flex-wrap: wrap;
}
.capability-heading span {
  color: var(--lh-text-secondary);
  font-size: 12px;
}
.capability-cell small {
  display: block;
  margin-top: 4px;
  color: var(--lh-text-secondary);
  white-space: normal;
}
.ipv6-mode-options {
  display: flex;
  width: 100%;
  flex-direction: column;
  gap: 10px;
}
.ipv6-mode-options :deep(.el-radio) {
  width: 100%;
  height: auto;
  min-height: 72px;
  margin: 0;
  padding: 12px 14px;
  align-items: flex-start;
  white-space: normal;
}
.ipv6-mode-options :deep(.el-radio__label) {
  display: flex;
  min-width: 0;
  flex-direction: column;
  gap: 4px;
  line-height: 20px;
  white-space: normal;
}
.mode-title {
  flex-wrap: wrap;
  color: var(--lh-text);
  font-weight: 600;
}
.mode-description { color: var(--lh-text-secondary); font-size: 12px; }

@media (max-width: 767px) {
  .handling-impact-grid {
    grid-template-columns: 1fr;
  }
}
</style>
