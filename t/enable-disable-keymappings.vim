let g:annoyme_errcmd = ":echoerr 'This is Vim! Use `%s` instead!'"

source t/helpers/remaparrows.vim
source plugin/annoyme.vim

describe ':AnnoyMe'

  before
    read t/fixtures/sample.txt
    :AnnoyMe
  end

  it 'Arrows and other mapped keys should never move the cursor'
    call cursor(4, 40)
    Expect getpos('.')[1:2] == [4, 40]
    for i in range(65, 70)
      try
        exe 'normal' printf("%c", i)
      catch /This is Vim!/
      endtry
      Expect getpos('.')[1:2] == [4, 40]
    endfor
  end

end

describe ':AnnoyMeNot'

  before
    read t/fixtures/sample.txt
    :AnnoyMeNot
  end

  it 'Arrows and other annoyances should be disabled'
    call cursor(4, 40)
    Expect getpos('.')[1:2] == [4, 40]
    for i in range(65, 70)
      exe 'normal' printf("%c", i)
    endfor
    Expect getpos('.')[1:2] == [12, 52]
  end

end
" vim: sw=2 sts=2 ai et