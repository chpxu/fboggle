! -----------------------------------------------------------------------------
! Benchmark
! -----------------------------------------------------------------------------

!!*** benchmarks/benchmark.f90 *
!!  NAME
!!   benchmark_params
!!  PURPOSE
!!   Generates random test cases for fboggle
!!  USES
!!  AUTHOR
!!   chpxu
!!  CREATION DATE
!!   23/11/2026
!!  MODIFICATION HISTORY
!!    24/11/2026 chpxu: Support multiple letters per tile and iso_fortran_env
!***

module benchmark_params

   use, intrinsic :: iso_fortran_env, idp => int64
   use, intrinsic :: iso_fortran_env, rdp => real64
   implicit none

   integer(idp), parameter :: GRID_SIZES(9) = [4, 8, 16, 32, &
                                               64, 128, 256, 512, 1024]

   integer(idp), parameter :: TILE_LENGTHS(3) = [1, 2, 3]

   integer(idp), parameter :: SEED_VALUE = 20261124
   integer(idp), parameter :: ALPHABET_SIZE = 26
   character(len=ALPHABET_SIZE), parameter :: ALPHABET = 'abcdefghijklmnopqrstuvwxyz'
   integer(idp), parameter :: LETTER_WEIGHTS(ALPHABET_SIZE) = [8, 2, 3, 4, 12, 2, 2, 6, 7, 1, &
                                                               1, 4, 2, 7, 8, 2, 1, 6, 6, 9, 3, 1, 2, 1, 2, 1]

   character(len=256), parameter :: benchmark_dir = "./benchmarks"
end module benchmark_params
program BoggleBenchmark
   use benchmark_params
   implicit none

   character(len=256)  :: filename
   character(len=:), allocatable :: row_letters(:)
   integer, allocatable :: seeds(:)
   integer :: seed_length
   integer(idp) :: i, idx, tile_idx, letter_pos, n_letters, grid_size, tile_len, row_idx, column_idx
   integer(idp) :: iounit, ios
   real(rdp) :: random_real
   call random_seed(size=seed_length)
   seeds = SEED_VALUE + [(26*i, i=1, seed_length)]
   call random_seed(put=seeds)
   do tile_idx = 1, size(TILE_LENGTHS)
      tile_len = TILE_LENGTHS(tile_idx)
      do idx = 1, size(GRID_SIZES)
         grid_size = GRID_SIZES(idx)
         ! Write params_"grid_size".txt
         write (filename, '(a,"/params_",i0,"x",i0,"_t",i0,".txt")') &
            trim(benchmark_dir), grid_size, grid_size, tile_len

         open (newunit=iounit, file=filename, status='replace', action='write', iostat=ios)
         if (ios /= 0) then
            print '(2A)', 'Error writing params file: ', trim(filename)
            stop
         end if ! ios /=0
         write (iounit, '(I0)') grid_size
         write (iounit, '(I0)') tile_len
         allocate (character(len=tile_len) :: row_letters(grid_size))
         do row_idx = 1, grid_size
            do column_idx = 1, grid_size
               call random_number(random_real)
               n_letters = int(random_real*tile_len) + 1
               row_letters(column_idx) = ''
               do letter_pos = 1, n_letters
                  row_letters(column_idx) (letter_pos:letter_pos) = random_letter()
               end do ! letter_pos
            end do ! random_letter column

            write (iounit, '(*(A,:,1x))') row_letters
         end do ! row
         deallocate (row_letters)
         close (iounit)
      end do ! idx = 1, size(GRID_SIZES)
   end do ! TILE_LENGTHS
contains
   function random_letter() result(letter)
      use benchmark_params, only: ALPHABET, ALPHABET_SIZE, LETTER_WEIGHTS, rdp

      implicit none

      character :: letter
      real(rdp) :: random_real
      integer :: target_weight, cumsum, letter_idx

      call random_number(random_real)
      target_weight = int(random_real*sum(LETTER_WEIGHTS))
      cumsum = 0
      do letter_idx = 1, ALPHABET_SIZE
         cumsum = cumsum + LETTER_WEIGHTS(letter_idx)
         if (target_weight < cumsum) then
            letter = ALPHABET(letter_idx:letter_idx)
            return
         end if
      end do ! letter_idx
   end function random_letter
end program BoggleBenchmark
