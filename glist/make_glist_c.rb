require 'json'
require 'set'

$aglfn = Hash.new(false)
f = File.open('aglfn.txt', 'r:utf-8')
f.each { |s|
	s.chomp!
	next if s == ''
	next if s[0] == '#'

	uni, name, d = s.split(/;/, 3)
	$aglfn[uni.to_i(16)] = name
}
f.close

$zhorder = Hash.new(0)
f = File.open('zht_order.txt', 'r:utf-8')
f.each { |s|
	s.chomp!
	next if s == ''
	next if s[0] == '#'

	no, c, cnt, sum, rate = s.split(/\t/)
	$zhorder[c] = cnt.gsub(/\D/, '').to_i
}
f.close

Wmap = {'比例'=>'P', '半形'=>'H', '全形'=>'F'}
GlyphInfo = Struct.new(:name, :seq, :width, :note, :vert, :seqs, :full, :cnt) do
	def sort_val
		if seq.length == 1
			sprintf('%06X', seq.ord)
		else 
			name =~ /uni([A-Z0-9]{4}\.vert)/ ? name.gsub(/^uni/, '00') : name
		end
	end

	def to_json(*_args)
		h = { c: seq, w: Wmap[width] }
		h[:n] = note if note
		h[:v] = vert if vert
		h[:s] = seqs if seqs
		h[:f] = full if full
		h.to_json
	end
end

$glist = {}
$cmap = Hash.new(nil)
$fulls = Set.new()

def read_list fn, ctype, col=nil
	list = {}
	lastno = nil
	f = File.open(fn, 'r:utf-8')
	f.each { |s|
		s.chomp!
		next if s == ''
		next if s !~ /^\d/

		tmp = s.split(/\t/)
		no = tmp[0].to_i
		seq = tmp[1]
		uni = tmp[2] != '' ? tmp[2].to_i(16) : nil
		next if col && tmp[col] != 'V'

		if uni && ctype == :H		# 漢字		 && !$nicenames[uni]
			gname = sprintf(uni <= 0xffff ? 'uni%04X' : 'u%05X', uni)
			$glist[gname] = GlyphInfo.new(gname, seq, '全形')
			$glist[gname].cnt = $zhorder[seq]
			$cmap[seq] = gname
			list[no] = gname
		elsif uni					# 符號
			next if tmp[4] == '兩倍全形'
			next if [0x20, 0x2c9, 0x3000, 0xA0, 0x2002].include?(uni)	# 空格、全形空格、半形空格
			#next if (0xFF10..0xFF19).include?(uni)	# 全形數字
			#next if (0xFF20..0xFF3A).include?(uni)	# 全形大寫
			#next if (0xFF41..0xFF5A).include?(uni)	# 全形小寫

			gname = $aglfn[uni] || sprintf(uni <= 0xffff ? 'uni%04X' : 'u%05X', uni)
			next if $fulls.include?(gname)
			$glist[gname] = GlyphInfo.new(gname, seq, tmp[4], tmp[5])
			$cmap[seq] = gname

			if tmp[5] =~ /直排/
				$glist[gname].vert = list[lastno]
			elsif gname == 'uniFF1A' || gname == 'uniFF1B'
				$glist[gname].vert = gname
			end
			if (0x30..0x39).include?(uni) || (0x40..0x5A).include?(uni) || (0x61..0x7A).include?(uni)
				$fulls << $glist[gname].full = sprintf('uni%04X', uni + 0xfee0)
				$glist[gname].note.gsub!(/半形/, '') if $glist[gname].note
			end

			list[no] = gname
		elsif seq != ''					# 符號-組合字
			seqs = seq.split(//).map { |c| $cmap[c] }
			gname = seqs.join('_')
			# seq.each_char { |c|
			# 	puts "#{seq} !!!" if c.ord > 0xffff
			# 	gname += sprintf('%04X', c.ord)
			# }
			$glist[gname] = GlyphInfo.new(gname, seq, tmp[4], tmp[5])
			#seqs = seq.split(//).map { |c| $cmap[c] }
			$glist[gname].seqs = seqs if seqs.size > 1
			list[no] = gname

			puts gname if seqs.size == 1

			#list << ['ccmp', "sub #{tokens.join(' ')} by #{tokens.join('_')};"]
		else							# 符號-直排
			lastg = list[lastno]
			if lastg != 'uniFF1A' && lastg != 'uniFF1B'
				gname = lastg + '.vert'
				$glist[gname] = GlyphInfo.new(gname, $glist[lastg].seq, tmp[4], tmp[5], lastg)
				list[no] = gname
			end
		end
		lastno = no
	}
	f.close

	#list.sort_by { |k, v| k }.map { |k, v| v }
	ctype == :H ? list.sort_by { |k, v| -$glist[v].cnt }.map { |k, v| v } : list.sort_by { |k, v| k }.map { |k, v| v }

	#list.size > 0 ? list : nil
end

verybaselist = ('a'..'z').to_a + ('A'..'Z').to_a
verybaselist += ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'comma', 'period', 'hyphen']

baselist = verybaselist + ['uni02CA', 'caron', 'uni02CB', 'dotaccent']
('ㄅ'..'ㄩ').to_a.each { |c| baselist << sprintf('uni%04X', c.ord) }
'一二三四五六七八九十微風迎客軟語伴茶，。'.split(//).each { |c| baselist << sprintf('uni%04X', c.ord) }

result_tmp = {
	'基礎字' => baselist,
	'基本包-漢字' => read_list('han_base.txt', :H),
	'基本包-符號' => read_list('sym_base.txt', :S),
	'本土包-漢字' => read_list('han_ext.txt', :H, 4),
	'本土包-符號' => read_list('sym_ext.txt', :S, 6),
	'日文包-漢字' => read_list('han_ext.txt', :H, 5),
	'日文包-符號' => read_list('sym_ext.txt', :S, 7),
	'粵語包-漢字' => read_list('han_ext.txt', :H, 6),
	'粵語包-符號' => read_list('sym_ext.txt', :S, 8),
	'命名包-漢字' => read_list('han_ext.txt', :H, 7),
	'命名包-符號' => read_list('sym_ext.txt', :S, 9),
	'補充符號包' => read_list('sym_ext.txt', :S, 10)
}

result_tmp['附表：台文全羅'] = verybaselist + result_tmp['本土包-符號']
result_tmp['附表：心經'] = []
'般若波羅蜜多心經觀自在菩薩行深般若波羅蜜多時照見五蘊皆空度一切苦厄舍利子色不異空空不異色色即是空空即是色受想行識亦復如是舍利子是諸法空相不生不滅不垢不淨不增不減是故空中無色無受想行識無眼耳鼻舌身意無色聲香味觸法無眼界乃至無意識界無無明亦無無明盡乃至無老死亦無老死盡無苦集滅道無智亦無得以無所得故菩提薩埵依般若波羅蜜多故心無罣礙無罣礙故無有恐怖遠離顛倒夢想究竟涅槃三世諸佛依般若波羅蜜多故得阿耨多羅三藐三菩提故知般若波羅蜜多是大神咒是大明咒是無上咒是無等等咒能除一切苦真實不虛故說般若波羅蜜多咒即說咒曰揭諦揭諦波羅揭諦波羅僧揭諦菩提薩婆訶'.split(//).each { |c| result_tmp['附表：心經'] << sprintf('uni%04X', c.ord) }

$glist = $glist.sort_by { |k, v| v.sort_val }.to_h


result_tmp['基礎字'] |= result_tmp['基本包-漢字'].shift(100)

pagesize = 420
result = {}
result_tmp.each { |k, v|
	puts "Processing #{k} with #{v.size} items"
	puts "  -- #{(v.size * 1.0 / pagesize).ceil} pages with #{v.size % pagesize} items in last page" if v.size > pagesize

	next if v.size == 0
	if v.size > pagesize
		(v.size / pagesize.to_f).ceil.times { |i|
			result["#{k}##{i+1}"] = v[i * pagesize, pagesize]
		}
	else
		result[k] = v
	end
}

f = File.open('../pages/cglyphlist.js', 'w:utf-8')
f.puts "const glyphMap = #{JSON.pretty_generate($glist)};"
#f.puts "const glyphList = #{JSON.pretty_generate(result)};"
#f.puts "const glyphMap = #{$glist.to_json};"
f.puts "const glyphList = #{result.to_json};"
f.close
