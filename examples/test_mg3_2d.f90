!> \example test_mg2_2d.f90
!> Example showing how to use m_mg_2d for a jumping coefficient (e.g.,
!> a jump in dielectric constant in electrostatics)
program test_mg3_2d
  use m_afivo_2d
  use m_mg_2d

  implicit none

  integer, parameter :: dp           = kind(0.0d0)
  integer, parameter :: box_size     = 2
  integer, parameter :: n_boxes_base = 1
  integer, parameter :: i_phi = 1, i_tmp = 2
  integer, parameter :: i_rhs = 3, i_eps = 4
  integer, parameter :: i_fld = 5

  type(a2_t)         :: tree
  type(ref_info_t)   :: ref_info
  integer            :: i, id
  integer            :: ix_list(2, n_boxes_base)
  integer            :: nb_list(4, n_boxes_base)
  real(dp)           :: dr
  character(len=40)  :: fname, var_names(5)
  type(mg2_t)        :: mg

  var_names(i_phi) = "phi"
  var_names(i_tmp) = "tmp"
  var_names(i_rhs) = "rhs"
  var_names(i_fld) = "fld"
  var_names(i_eps) = "eps"

  dr = 1.0_dp / box_size

  ! Initialize tree
  call a2_init(tree, box_size, n_var_cell=5, n_var_face=0, dr = dr)

  id = 1
  ix_list(:, id) = [1,1]         ! Set index of boxnn
  nb_list(:, id) = -1            ! Dirichlet zero -> -1

  call a2_set_base(tree, ix_list, nb_list)

  do i = 1, 20
     call a2_adjust_refinement(tree, set_ref_flags, ref_info)
     if (ref_info%n_add == 0) exit
  end do

  ! Set rhs and initial guess for phi
  call a2_loop_box(tree, set_init_cond)

  ! Set the multigrid options
  mg%i_phi    = i_phi
  mg%i_tmp    = i_tmp
  mg%i_rhs    = i_rhs
  mg%i_eps    = i_eps
  mg%sides_bc => sides_bc
  mg%box_op   => mg2_box_lpld
  mg%box_gsrb => mg2_box_gsrb_lpld
  mg%box_corr => mg2_box_corr_lpld

  call mg2_init_mg(mg)

  do i = 1, 10
     ! call mg2_fas_vcycle(tree, mg, tree%n_lvls)
     call mg2_fas_fmg(tree, mg, .true., i == 1)
     call a2_loop_box(tree, fld_from_pot)
     write(fname, "(A,I0)") "test_mg3_2d_", i
     call a2_write_vtk(tree, trim(fname), var_names, i, 0.0_dp)
  end do

  print *, "max_id", tree%max_id
  print *, "n_cells", tree%max_id * tree%n_cell**2

  call a2_destroy(tree)

contains

  subroutine set_ref_flags(boxes, id, ref_flags)
    type(box2_t), intent(in) :: boxes(:)
    integer, intent(in)      :: id
    integer, intent(inout)   :: ref_flags(:)

    ref_flags(id) = a5_rm_ref

    if (boxes(id)%lvl < 4 .or. (boxes(id)%lvl < 7 .and. &
         a2_r_inside(boxes(id), [0.5_dp, 0.5_dp], 5*boxes(id)%dr))) then
       ref_flags(id) = a5_do_ref
    else
       ref_flags(id) = a5_kp_ref
    end if
  end subroutine set_ref_flags

  subroutine set_init_cond(box)
    type(box2_t), intent(inout) :: box
    integer                     :: i, j, nc
    real(dp)                    :: xy(2)

    nc = box%n_cell
    box%cc(:, :, i_phi) = 0

    do j = 0, nc+1
       do i = 0, nc+1
          xy = a2_r_cc(box, [i,j])
          box%cc(i, j, i_rhs) = 0.0_dp
          if (xy(2) < 0.5) then
             box%cc(i, j, i_eps) = 1.0_dp
          else
             box%cc(i, j, i_eps) = 4.0_dp
          end if
       end do
    end do
  end subroutine set_init_cond

  subroutine sides_bc(boxes, id, nb, iv)
    type(box2_t), intent(inout) :: boxes(:)
    integer, intent(in)         :: id, nb, iv
    integer                     :: nc

    nc = boxes(id)%n_cell

    select case (nb)
    case (a2_nb_lx)
       ! Neumann zero
       boxes(id)%cc(0, 1:nc, iv) = boxes(id)%cc(1, 1:nc, iv)
    case (a2_nb_hx)
       ! Neumann zero
       boxes(id)%cc(nc+1, 1:nc, iv) = boxes(id)%cc(nc, 1:nc, iv)
    case (a2_nb_ly)
       ! Dirichlet zero
       boxes(id)%cc(1:nc, 0, iv) = -boxes(id)%cc(1:nc, 1, iv)
    case (a2_nb_hy)
       ! Dirichlet one
       boxes(id)%cc(1:nc, nc+1, iv) = 2 - boxes(id)%cc(1:nc, nc, iv)
    end select
  end subroutine sides_bc

  subroutine fld_from_pot(box)
    type(box2_t), intent(inout) :: box
    integer                     :: nc
    real(dp) :: inv_dr

    nc = box%n_cell
    inv_dr = 0.5_dp / box%dr
    box%cc(1:nc, 1:nc, i_fld) = sqrt(inv_dr**2 * ( &
         (box%cc(2:nc+1, 1:nc, i_phi) - box%cc(0:nc-1, 1:nc, i_phi))**2 + &
         (box%cc(1:nc, 2:nc+1, i_phi) - box%cc(1:nc, 0:nc-1, i_phi))**2))
  end subroutine fld_from_pot

end program
